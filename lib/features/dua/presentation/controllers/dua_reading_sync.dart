import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:tuhfatul_muslim/features/amol_tracking/presentation/state/amol_daily_store.dart';
import 'package:tuhfatul_muslim/features/dua/data/repositories/dua_reading_repository_impl.dart';
import 'package:tuhfatul_muslim/features/dua/data/services/dua_offline_reading_progress_store.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_reading_repository.dart';

/// Sends the dua reading kept on the device (read offline, or left by an app
/// that closed mid-visit) once the server can be reached: at app start,
/// whenever the app comes back to the foreground, and, while reports still
/// wait, again after [retryAfter] (each wait longer, the last repeating) as
/// long as the app stays in the foreground.
///
/// The server then adds the time to the day's dua reading record, and so to
/// its Amol point, under the date each report was read; once any arrive,
/// today's Amol checklist ([AmolDailyStore]) is reloaded for the Home cards.
class DuaReadingSync {
  DuaReadingSync(
    this._repository, {
    this.retryAfter = const [
      Duration(seconds: 30),
      Duration(minutes: 1),
      Duration(minutes: 2),
      Duration(minutes: 5),
    ],
    void Function()? onSent,
  }) : _onSent = onSent ?? (() => unawaited(AmolDailyStore.instance.load()));

  static final shared = DuaReadingSync(DuaReadingRepositoryImpl.shared);

  final DuaReadingRepository _repository;
  final List<Duration> retryAfter;
  final void Function() _onSent;

  AppLifecycleListener? _lifecycle;
  Timer? _retry;
  int _retries = 0;
  bool _foreground = true;

  /// Starts syncing; call once, after local storage is ready.
  void start() {
    // Restore the durable local projection before this launch starts
    // sending reports left by the previous one.
    unawaited(DuaOfflineReadingProgressStore.shared.restore());
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
      final result = await _repository.syncPendingReadings();
      if (result.sent > 0) _onSent();
      if (result.pending == 0) {
        _retries = 0;
      } else if (_foreground && retryAfter.isNotEmpty) {
        final wait = retryAfter[_retries.clamp(0, retryAfter.length - 1)];
        _retries++;
        _retry = Timer(wait, () => unawaited(sync()));
      }
    } catch (error) {
      debugPrint('Dua reading not synced: $error');
    }
  }

  @visibleForTesting
  bool get debugRetryScheduled => _retry?.isActive ?? false;

  void dispose() {
    _lifecycle?.dispose();
    _lifecycle = null;
    _retry?.cancel();
  }
}
