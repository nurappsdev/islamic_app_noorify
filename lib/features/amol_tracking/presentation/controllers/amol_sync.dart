import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:tuhfatul_muslim/features/amol_tracking/data/repositories/amol_tracking_repository_impl.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/repositories/amol_tracking_repository.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/state/amol_daily_store.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';

/// Sends the Amol ticks kept on the device once the server can be reached,
/// with nothing for the user to do and nothing for them to see: at app start,
/// whenever the app comes back to the foreground, and — while ticks are still
/// waiting — again after each wait in [retryAfter] (the last one repeating)
/// for as long as the app stays in the foreground.
///
/// There is no connectivity listener to go wrong: a sync attempt simply fails
/// quietly while offline and the next wait is a little longer, which is what
/// the Quran reading sync does too. Nothing is ever shown — no snackbar, no
/// dialog, no notification. Once ticks do land, today's checklist
/// ([AmolDailyStore]) is reloaded so the Home cards agree with the server.
class AmolSync {
  AmolSync(
    this._repository, {
    this.retryAfter = const [
      Duration(seconds: 5),
      Duration(seconds: 15),
      Duration(seconds: 45),
      Duration(minutes: 2),
      Duration(minutes: 5),
    ],
    void Function()? onSent,
    bool Function()? isSignedIn,
  }) : _onSent = onSent ?? (() => unawaited(AmolDailyStore.instance.load())),
       _isSignedIn = isSignedIn ?? _hasToken;

  static final shared = AmolSync(AmolTrackingRepositoryImpl.shared);

  final AmolTrackingRepository _repository;
  final List<Duration> retryAfter;
  final void Function() _onSent;
  final bool Function() _isSignedIn;

  AppLifecycleListener? _lifecycle;
  Timer? _retry;
  int _retries = 0;
  bool _foreground = true;

  static bool _hasToken() {
    try {
      return AuthLocalDataSourceImpl().hasToken;
    } catch (_) {
      // Storage not ready: treat as signed out and try again later.
      return false;
    }
  }

  /// Starts syncing; call once, after local storage is ready.
  void start() {
    _lifecycle ??= AppLifecycleListener(
      onResume: () {
        _foreground = true;
        unawaited(sync());
      },
      onHide: () {
        _foreground = false;
        _retry?.cancel();
      },
    );
    unawaited(sync());
  }

  /// Sends what is waiting now. Never throws.
  Future<void> sync() async {
    _retry?.cancel();
    try {
      // Nothing may be sent under a token that isn't there: a signed-out
      // device would only collect refusals.
      if (!_isSignedIn()) {
        _scheduleRetry();
        return;
      }
      final result = await _repository.syncPending();
      if (result.sent > 0) _onSent();
      if (result.pending == 0) {
        _retries = 0;
      } else {
        _scheduleRetry();
      }
    } catch (error) {
      debugPrint('Amol ticks not synced: $error');
    }
  }

  void _scheduleRetry() {
    if (!_foreground || retryAfter.isEmpty) return;
    final wait = retryAfter[_retries.clamp(0, retryAfter.length - 1)];
    _retries++;
    _retry = Timer(wait, () => unawaited(sync()));
  }

  @visibleForTesting
  bool get debugRetryScheduled => _retry?.isActive ?? false;

  void dispose() {
    _lifecycle?.dispose();
    _lifecycle = null;
    _retry?.cancel();
  }
}
