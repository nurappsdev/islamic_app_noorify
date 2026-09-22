import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:islami_app_noorify/features/hadith/domain/usecases/track_hadith_reading.dart';

/// Tunables of the reading tracker.
abstract final class HadithReadingConfig {
  /// The user must spend MORE than this many seconds on the screen before
  /// leaving it asks "Have you completed reading this Hadith?" and reports the
  /// time. At or below it, they leave normally and nothing is sent.
  static const minSeconds = 30;

  /// Once a hadith has been in focus for this many seconds, the screen asks
  /// "Your reading time is complete" on its own, without waiting for the
  /// user to leave.
  static const autoCompleteSeconds = 300;
}

enum HadithCompletion { done, alreadyCompleted, failed }

/// Measures how long the user stays on the hadith screen and reports it to the
/// backend (`POST /hadiths/reading/track`).
///
/// * A one-second clock counts the time on the screen, except while it is
///   [pause]d (the app is in the background, or another screen is on top).
///   Alongside, it notes which hadith the screen shows in focus each second,
///   so the time can be attributed to the hadith read the longest.
/// * Nothing is sent while the user reads. A report goes out only when the
///   user answers the leave dialog ([submit]) or presses a Complete button.
/// * The leave dialog is asked at most once, and never after a report was
///   already sent in this session. A hadith completed once is remembered on
///   the device and never reported as completed again.
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

  /// Seconds already reported (so a later report sends only the new time).
  int _sent = 0;

  /// Seconds each hadith spent in focus.
  final Map<String, int> _dwell = {};
  final Set<String> _completed = {};
  final Set<String> _completing = {};

  bool _paused = false;
  bool _reported = false;
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

  /// One second on the screen, spent on [hadithId] if one is in focus.
  @visibleForTesting
  void tick(String? hadithId) {
    if (_paused) return;
    _elapsed++;
    if (hadithId != null) _dwell[hadithId] = (_dwell[hadithId] ?? 0) + 1;
    _onTick?.call(hadithId);
  }

  int get elapsedSeconds => _elapsed;

  /// Seconds [hadithId] has spent in focus so far, e.g. for a per-hadith
  /// reading timer in the UI.
  int dwellSeconds(String hadithId) => _dwell[hadithId] ?? 0;

  bool isCompleted(String hadithId) => _completed.contains(hadithId);

  bool isCompleting(String hadithId) => _completing.contains(hadithId);

  /// The hadith that was in focus the longest and isn't completed yet — the
  /// one the leave dialog is about. Null if none was ever in focus.
  String? get reportCandidate {
    String? best;
    var bestSeconds = 0;
    _dwell.forEach((id, seconds) {
      if (_completed.contains(id) || _completing.contains(id)) return;
      if (seconds > bestSeconds) {
        best = id;
        bestSeconds = seconds;
      }
    });
    return best;
  }

  /// Whether leaving should ask "Have you completed reading this Hadith?":
  /// more than [minSeconds] on the screen, a hadith to ask about, and nothing
  /// reported yet this session.
  bool get shouldAskOnLeave =>
      !_reported && _elapsed > minSeconds && reportCandidate != null;

  /// Reports the time on the screen for [hadithId], completed or not. Sends
  /// nothing (and returns [HadithCompletion.alreadyCompleted]) if that hadith
  /// is already completed or a report for it is in flight.
  Future<HadithCompletion> submit(
    String hadithId, {
    required bool completed,
  }) async {
    if (_completed.contains(hadithId) || _completing.contains(hadithId)) {
      return HadithCompletion.alreadyCompleted;
    }
    _completing.add(hadithId);
    notifyListeners();
    final seconds = _elapsed - _sent;
    try {
      final result = await _track(
        hadithId: hadithId,
        seconds: seconds,
        completed: completed,
        date: _now(),
      );
      return await result.fold((_) => HadithCompletion.failed, (_) async {
        _sent += seconds;
        _reported = true;
        if (completed) {
          _completed.add(hadithId);
          await _saveCompleted();
        }
        return HadithCompletion.done;
      });
    } finally {
      _completing.remove(hadithId);
      notifyListeners();
    }
  }

  /// [submit] with `completed: true` — the Complete button, or "Yes".
  Future<HadithCompletion> complete(String hadithId) =>
      submit(hadithId, completed: true);

  Future<void> _saveCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_completedKey, _completed.toList());
    } catch (_) {
      // Still completed for this run.
    }
  }
}
