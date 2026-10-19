import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:tuhfatul_muslim/features/amol_tracking/presentation/state/amol_daily_store.dart';
import 'package:tuhfatul_muslim/features/quran/data/repositories/quran_reading_repository_impl.dart';
import 'package:tuhfatul_muslim/features/quran/domain/repositories/quran_reading_repository.dart';

/// Sends the Quran reading kept on the device (read offline, or left by an
/// app that closed mid-session) once the server can be reached: at app
/// start, whenever the app comes back to the foreground, and, while reports
/// still wait, again after [retryAfter] (each wait longer, the last
/// repeating) as long as the app stays in the foreground.
///
/// The server then updates the day's Quran reading record, and so its Amol
/// check, under the date each report was read; once any arrive, today's
/// Amol checklist ([AmolDailyStore]) is reloaded for the Home cards.
class QuranReadingSync {
  QuranReadingSync(
    this._repository, {
    this.retryAfter = const [
      Duration(seconds: 30),
      Duration(minutes: 1),
      Duration(minutes: 2),
      Duration(minutes: 5),
    ],
    void Function()? onSent,
  }) : _onSent = onSent ?? (() => unawaited(AmolDailyStore.instance.load()));

  static final shared = QuranReadingSync(QuranReadingRepositoryImpl.shared);

  final QuranReadingRepository _repository;
  final List<Duration> retryAfter;
  final void Function() _onSent;

  AppLifecycleListener? _lifecycle;
  Timer? _retry;
  int _retries = 0;
  bool _foreground = true;

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
      debugPrint('Quran reading not synced: $error');
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
