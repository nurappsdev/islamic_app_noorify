import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:islami_app_noorify/features/hadith/domain/usecases/track_hadith_reading.dart';

/// Tunables of the reading tracker.
abstract final class HadithReadingConfig {
  /// The user must spend MORE than this many seconds in focus on a hadith
  /// before it counts as a candidate to report: the leave dialog offers to
  /// mark it read, and its Yes checkbox becomes visible. At or below it,
  /// nothing is reported for that hadith.
  static const minSeconds = 30;

  /// Once a hadith has been in focus for this many seconds, the screen asks
  /// "Your reading time is complete" on its own, without waiting for the
  /// user to leave.
  static const autoCompleteSeconds = 300;
}

enum HadithCompletion { done, alreadyCompleted, failed }

/// Measures how long the user stays on the hadith screen and reports it to
/// the backend (`POST /learning/reading/track`), one or more hadiths at a
/// time.
///
/// * A one-second clock counts the time on the screen, except while it is
///   [pause]d (the app is in the background, or another screen is on top).
///   Alongside, it notes which hadith the screen shows in focus each second,
///   so time is attributed per hadith ([dwellSeconds]).
/// * Nothing is sent while the user reads. A report goes out only through
///   [submit] (or its single-hadith shorthand, [complete]) — the leave
///   dialog, the Yes checkbox, or the 5-minute auto-complete dialog.
/// * Once a hadith is reported as completed, its dwell time freezes (see
///   [tick]) — its timer visibly stops — and it is remembered on the device,
///   so it is never reported again.
class HadithReadingTracker extends ChangeNotifier {
  HadithReadingTracker(
    this._track, {
    DateTime Function()? now,
    this.minSeconds = HadithReadingConfig.minSeconds,
  }) : _now = now ?? DateTime.now;

  static const _completedKey = 'hadith_completed_ids';

  final TrackHadithReading _track;
  final DateTime Function() _now;
  final int minSeconds;

  /// Seconds spent on the screen.
  int _elapsed = 0;

  /// Seconds each hadith spent in focus. Stops growing once that hadith is
  /// in [_completed] (see [tick]).
  final Map<String, int> _dwell = {};
  final Set<String> _completed = {};
  final Set<String> _completing = {};

  bool _paused = false;
  bool _disposed = false;
  Timer? _timer;

  /// Says which hadith is in focus; set by [start], cleared by [stop].
  String? Function()? _focus;

  /// Notified with the focused hadith id on every tick, e.g. to drive a
  /// per-hadith reading timer in the UI. Set by [start], cleared by [stop].
  void Function(String? focusedId)? _onTick;

  /// Loads the hadiths already completed on this device.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _completed.addAll(prefs.getStringList(_completedKey) ?? const []);
      notifyListeners();
    } catch (_) {
      // Start with none completed.
    }
  }

  /// Starts the clock. [focusedHadithId] says which hadith is in view right
  /// now (null while none is). [onTick], if given, is called with the
  /// focused hadith id every second the clock actually ticks.
  void start(
    String? Function() focusedHadithId, {
    void Function(String? focusedId)? onTick,
  }) {
    _focus = focusedHadithId;
    _onTick = onTick;
    _schedule();
  }

  /// (Re)creates the one-second timer, or leaves none running if the tracker
  /// is paused, stopped or disposed. There is never more than one timer.
  void _schedule() {
    _timer?.cancel();
    _timer = null;
    final focus = _focus;
    if (focus == null || _paused || _disposed) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick(focus()));
  }

  /// Cancels the timer for good and drops the focus callback (which holds on
  /// to the screen's state). Safe to call more than once.
  void stop() {
    _focus = null;
    _onTick = null;
    _timer?.cancel();
    _timer = null;
  }

  /// Whether the one-second timer is running.
  bool get isRunning => _timer != null;

  @override
  void notifyListeners() {
    // A report can finish after the screen (and this tracker) is gone.
    if (!_disposed) super.notifyListeners();
  }

  /// Cancels the timer and clears the temporary state of this screen visit.
  /// A report already on its way still finishes (and is remembered), quietly.
  @override
  void dispose() {
    if (_disposed) return;
    stop();
    _dwell.clear();
    _disposed = true;
    super.dispose();
  }

  /// Stops counting *and* cancels the timer, so nothing ticks while another
  /// screen is on top or the app is in the background. [resume] restarts it.
  void pause() {
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  void resume() {
    _paused = false;
    _schedule();
  }

  /// One second on the screen, spent on [hadithId] if one is in focus. A
  /// hadith already reported as completed no longer accrues dwell time — its
  /// timer has stopped for good.
  @visibleForTesting
  void tick(String? hadithId) {
    if (_paused) return;
    _elapsed++;
    if (hadithId != null && !_completed.contains(hadithId)) {
      _dwell[hadithId] = (_dwell[hadithId] ?? 0) + 1;
    }
    _onTick?.call(hadithId);
  }

  int get elapsedSeconds => _elapsed;

  /// Seconds [hadithId] has spent in focus so far, e.g. for a per-hadith
  /// reading timer in the UI. Frozen once that hadith [isCompleted].
  int dwellSeconds(String hadithId) => _dwell[hadithId] ?? 0;

  bool isCompleted(String hadithId) => _completed.contains(hadithId);

  bool isCompleting(String hadithId) => _completing.contains(hadithId);

  /// Hadiths read for more than [minSeconds] that haven't been reported (or
  /// aren't already being reported) — candidates for the leave dialog, or for
  /// the Yes checkbox to appear on.
  List<String> get reportCandidates => [
    for (final entry in _dwell.entries)
      if (entry.value > minSeconds &&
          !_completed.contains(entry.key) &&
          !_completing.contains(entry.key))
        entry.key,
  ];

  /// Whether leaving should ask to mark some hadiths as read: at least one
  /// [reportCandidates].
  bool get shouldAskOnLeave => reportCandidates.isNotEmpty;

  /// Reports the time spent on [hadithIds] (their [dwellSeconds] summed),
  /// completed or not. Ids already completed or already being reported are
  /// dropped first; if none are left, sends nothing and returns
  /// [HadithCompletion.alreadyCompleted].
  Future<HadithCompletion> submit(
    List<String> hadithIds, {
    required bool completed,
  }) async {
    final ids = [
      for (final id in hadithIds)
        if (!_completed.contains(id) && !_completing.contains(id)) id,
    ];
    if (ids.isEmpty) return HadithCompletion.alreadyCompleted;
    _completing.addAll(ids);
    notifyListeners();
    final seconds = ids.fold(0, (sum, id) => sum + dwellSeconds(id));
    try {
      final result = await _track(
        hadithIds: ids,
        seconds: seconds,
        completed: completed,
        date: _now(),
      );
      return await result.fold((_) => HadithCompletion.failed, (_) async {
        if (completed) {
          _completed.addAll(ids);
          await _saveCompleted();
        }
        return HadithCompletion.done;
      });
    } finally {
      _completing.removeAll(ids);
      notifyListeners();
    }
  }

  /// [submit] for a single hadith with `completed: true` — the Yes checkbox,
  /// or the 5-minute auto-complete dialog.
  Future<HadithCompletion> complete(String hadithId) =>
      submit([hadithId], completed: true);

  Future<void> _saveCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_completedKey, _completed.toList());
    } catch (_) {
      // Still completed for this run.
    }
  }
}
