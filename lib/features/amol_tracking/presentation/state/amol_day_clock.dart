import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;

import 'package:tuhfatul_muslim/features/amol_tracking/domain/amol_tracking_day.dart';

/// The Amol tracking day the whole app is on right now, as `YYYY-MM-DD`, and
/// the one announcement of the rollover everything else listens to.
///
/// The day is the device's own Gregorian calendar day (see
/// [amolTrackingDate]). [value] changes the moment it does — at midnight,
/// while the app is running — and the Home dashboard, the Amol tracker and
/// the shared checklist all answer that one notification by starting the new
/// day from zero. Nothing schedules its own rollover, so no two screens can
/// disagree about the date, and no view is left showing yesterday.
///
/// The rollover is noticed three ways, because one is not enough:
///
/// * a timer set for the next local midnight — so a running app turns over
///   exactly on the hour rather than at the next poll;
/// * a minute-by-minute check — so a timer that was suspended, or a clock or
///   timezone the user changed by hand, is still picked up;
/// * the app coming back to the foreground — so a device that slept through
///   midnight is up to date before its first frame is drawn.
class AmolDayClock extends ValueNotifier<String> {
  AmolDayClock({DateTime Function()? now, bool watchLifecycle = true})
    : _now = now ?? DateTime.now,
      super(amolTrackingDateIso((now ?? DateTime.now)())) {
    if (watchLifecycle) {
      try {
        _lifecycle = AppLifecycleListener(onResume: refresh);
      } catch (_) {
        // No widgets binding (a plain unit test): the timers below still
        // follow the day.
      }
    }
    _schedule();
    _safety = Timer.periodic(_safetyInterval, (_) => refresh());
  }

  /// The app-wide clock. Held for the app's lifetime.
  static final instance = AmolDayClock();

  /// A timer that fires a touch after midnight rather than exactly on it, so
  /// the date it then reads is never still yesterday's by a millisecond.
  static const _rolloverGuard = Duration(seconds: 1);

  /// Short enough that a missed midnight is corrected before the user can
  /// act on a stale day; costs one date comparison.
  static const _safetyInterval = Duration(minutes: 1);

  final DateTime Function() _now;
  AppLifecycleListener? _lifecycle;
  Timer? _rollover;
  Timer? _safety;

  /// Today's `YYYY-MM-DD`.
  String get date => value;

  /// Re-reads the clock, announcing a new day if one has begun. Safe to call
  /// as often as anything likes: on the same day it does nothing at all.
  void refresh() {
    final today = amolTrackingDateIso(_now());
    if (today != value) value = today;
    _schedule();
  }

  void _schedule() {
    _rollover?.cancel();
    final now = _now();
    final wait = nextAmolTrackingCheck(now).difference(now) + _rolloverGuard;
    _rollover = Timer(wait.isNegative ? _rolloverGuard : wait, refresh);
  }

  @override
  void dispose() {
    _rollover?.cancel();
    _safety?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }
}
