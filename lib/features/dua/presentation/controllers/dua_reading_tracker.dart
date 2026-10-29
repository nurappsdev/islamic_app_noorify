import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/features/amol_tracking/domain/amol_tracking_day.dart';
import 'package:tuhfatul_muslim/features/dua/data/services/dua_read_completion_store.dart';
import 'package:tuhfatul_muslim/features/dua/domain/dua_reading_points.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_reading_repository.dart';

/// Tunables of the dua reading tracker.
abstract final class DuaReadingTrackerConfig {
  /// Before this, a visit is not reported and the reader's "Read" checkbox
  /// stays hidden — `/duas/reading/track` refuses anything shorter.
  static const minSeconds = kDuaReadingMinReportSeconds;

  /// How often the time read so far is saved on the device, so closing the
  /// app loses at most this much.
  static const saveEvery = Duration(seconds: 30);
}

/// Measures one visit to the dua reader and reports it to
/// `POST /duas/reading/track`.
///
/// The clock starts with the screen and runs while the app is in the
/// foreground ([pause] stops it, [resume] restarts it); [elapsedSeconds] is
/// what the screen shows. Time comes from timestamps rather than from
/// counting ticks, so a late or dropped tick cannot lose a second.
///
/// Nothing is sent while the user reads. One report goes out at the end of
/// the visit — [complete] (the checkbox) or [finish] (leaving the screen) —
/// carrying the seconds not yet reported, which are claimed *before* the
/// request leaves. So however often either is called, and in whatever
/// order, the same second is never reported twice. The report is queued on
/// the device by the repository first, which is what makes a visit read
/// offline count once the server can be reached again.
///
/// Every [saveEvery] the visit so far is also saved as a draft, so an app
/// that is killed on this screen still has it reported on its next launch;
/// at each minute the same figure is published for the Amol cards, so the
/// Dua point appears the moment the fifth minute is reached — offline too.
///
/// Once the dua has been marked read, that is permanent: the device keeps
/// the record ([DuaReadCompletionStore]), so opening the same dua again
/// shows it read, with the duration that was recorded, and times nothing —
/// no further reading time is reported for it.
///
/// A visit that runs past midnight is split there: the minutes read before
/// it are reported for the day they were read in, and the visit starts again
/// from zero on the new day. Neither day is ever credited with the other's
/// time.
///
/// Day totals are the server's arithmetic: a visit reports only its own
/// seconds, and the half point per five minutes is awarded on the day's
/// accumulated time (see [duaReadingPointsForSeconds]). A new visit
/// therefore starts from zero without losing what the day has gathered.
class DuaReadingTracker extends ChangeNotifier {
  DuaReadingTracker(
    this._repository, {
    required this.duaId,
    DateTime Function()? now,
    DuaReadCompletionStore? completion,
    this.minSeconds = DuaReadingTrackerConfig.minSeconds,
    this.saveEvery = DuaReadingTrackerConfig.saveEvery,
  }) : _now = now ?? DateTime.now,
       _completion = completion ?? DuaReadCompletionStore.shared;

  final DuaReadingRepository _repository;

  /// The duas already marked read on this device.
  final DuaReadCompletionStore _completion;

  /// The dua being read — its own `_id`, never a mock catalog key.
  final String duaId;
  final DateTime Function() _now;
  final int minSeconds;

  /// Null: no drafts are saved.
  final Duration? saveEvery;

  /// Names the report, its drafts and its live figure, so each draft
  /// replaces the last and the report replaces them all. A fresh id is taken
  /// after every report, so a second report of the same visit cannot
  /// overwrite the first.
  String _reportId = newDuaReadingId();

  /// When the visit began — the day the reading is credited to.
  DateTime? _startedAt;
  Duration _banked = Duration.zero;
  DateTime? _runningSince;

  /// Seconds of this visit already handed to the repository.
  int _reported = 0;
  int _shownSeconds = 0;
  int _publishedMinute = 0;

  Timer? _ticker;
  Timer? _saver;
  bool _completed = false;

  /// True when [_completed] came from an earlier visit's record rather than
  /// from this one: there is no visit to report.
  bool _alreadyRead = false;
  bool _submitting = false;
  bool _paused = false;
  bool _finished = false;
  bool _disposed = false;

  /// Starts the clock, unless this dua has already been marked read — then
  /// nothing is timed and [isCompleted] is true from the start. Safe to call
  /// again; only the first call counts.
  void start() {
    if (_disposed || _startedAt != null || _completed) return;
    if (_completion.isCompleted(duaId)) {
      _restoreAlreadyRead();
      return;
    }
    // The record may not be loaded yet (first screen after a cold start):
    // read it, and stop the clock if this dua turns out to be read already.
    if (!_completion.isRestored) unawaited(_restoreCompletion());
    _startedAt = _now();
    _runningSince = _startedAt;
    _schedule();
  }

  Future<void> _restoreCompletion() async {
    await _completion.restore();
    if (_disposed || _completed || !_completion.isCompleted(duaId)) return;
    _restoreAlreadyRead();
    notifyListeners();
  }

  /// Shows the dua as read with the duration that was recorded, and leaves
  /// this visit untimed, so neither [complete] nor [finish] can report it.
  void _restoreAlreadyRead() {
    _completed = true;
    _alreadyRead = true;
    _startedAt = null;
    _runningSince = null;
    _banked = Duration(seconds: _completion.secondsFor(duaId));
    _shownSeconds = _banked.inSeconds;
    _stopClock();
  }

  /// Stops the clock — the app went to the background, so this time is not
  /// reading time — and saves what was read so far.
  void pause() {
    if (_paused || _disposed) return;
    _paused = true;
    _bank();
    _ticker?.cancel();
    _ticker = null;
    _saver?.cancel();
    _saver = null;
    unawaited(saveDraft());
  }

  /// Restarts the clock where it stopped.
  void resume() {
    if (!_paused || _disposed) return;
    _paused = false;
    if (_startedAt != null && !_completed) _runningSince = _now();
    _schedule();
  }

  /// Seconds of reading this visit. Frozen once the dua is marked read: the
  /// timer has stopped for good. For a dua read on an earlier visit, it is
  /// the duration that was recorded then.
  int get elapsedSeconds {
    final since = _runningSince;
    return (_banked +
            (since == null ? Duration.zero : _now().difference(since)))
        .inSeconds;
  }

  /// Whether the clock is ticking (not paused, not stopped).
  bool get isRunning => _ticker != null;

  /// Whether reading can be reported at all. A guest has no session to
  /// report under, so the screen asks them to sign in instead of checking
  /// the box.
  bool get canReport => _repository.isSignedIn;

  /// Whether this dua is marked read — this visit, or an earlier one whose
  /// record the device kept.
  bool get isCompleted => _completed;

  /// Whether a report is on its way right now (the checkbox's spinner).
  bool get isSubmitting => _submitting;

  /// Whether the "Read" checkbox may be offered: long enough to report, and
  /// not already read.
  bool get canComplete =>
      !_completed && !_submitting && elapsedSeconds >= minSeconds;

  /// Marks the dua read: reports the time read so far and stops the clock.
  /// Returns whether it is now marked read.
  ///
  /// The report is durable the moment the repository takes it, so a visit
  /// read offline counts as read here as well — it reaches the server with
  /// the next sync, under the date it was read.
  Future<bool> complete() async {
    if (_completed || _submitting || _disposed) return _completed;
    if (!_repository.isSignedIn) return false;
    // Ticked after midnight: the day that ended keeps its own minutes.
    _rollOverAtMidnight();
    _submitting = true;
    notifyListeners();
    try {
      final reported = await _report();
      // Nothing left to report only means this visit's time already went
      // out; the dua is read either way.
      if (!reported && _reported == 0) return false;
      _completed = true;
      _stopClock();
      // Read for good: the box stays checked on every later visit, and that
      // visit reports nothing.
      await _completion.markCompleted(duaId, seconds: elapsedSeconds);
      return true;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// Reports what is left of this visit and stops for good — called when the
  /// screen is left (Back, a swipe, or anything else that disposes it), just
  /// before [dispose]. Safe to call twice, and after [complete]: the seconds
  /// it already reported are not reported again. The report itself outlives
  /// the screen, so leaving never waits on the network.
  Future<void> finish() async {
    if (_finished) return;
    _finished = true;
    // Left after midnight: each day is reported with only its own time.
    if (!_alreadyRead) _rollOverAtMidnight();
    _stopClock();
    // Read on an earlier visit: this one was never timed.
    if (_alreadyRead) return;
    if (await _report()) return;
    // Too short to count: no later launch may send this visit either.
    if (_reported == 0) {
      await _repository.discardReadingDraft(_reportId);
    }
  }

  /// Saves the visit so far on the device (see [saveEvery]).
  @visibleForTesting
  Future<void> saveDraft() async {
    final startedAt = _startedAt;
    final seconds = elapsedSeconds - _reported;
    if (startedAt == null || seconds < minSeconds) return;
    await _repository.saveReadingDraft(
      sessionId: _reportId,
      duaId: duaId,
      seconds: seconds,
      date: startedAt,
    );
  }

  @override
  void notifyListeners() {
    // A report can finish after the screen, and this tracker, are gone.
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _stopClock();
    _disposed = true;
    super.dispose();
  }

  /// Hands the seconds not yet reported to the repository, claiming them
  /// first so nothing can report them a second time. Returns whether a
  /// report was made.
  Future<bool> _report() async {
    final startedAt = _startedAt;
    if (startedAt == null || !_repository.isSignedIn) return false;
    _bank();
    final seconds = elapsedSeconds - _reported;
    if (seconds < minSeconds) return false;
    final reportId = _reportId;
    // Claimed before the request goes out, and the next report gets its own
    // id: these seconds now belong to the repository's queue, delivered or
    // not, so they are never offered again.
    _reported += seconds;
    _reportId = newDuaReadingId();
    _publishedMinute = 0;
    try {
      await _repository.trackReading(
        duaId: duaId,
        seconds: seconds,
        date: startedAt,
        sessionId: reportId,
      );
    } catch (error) {
      // Reading goes on whatever happens to the report; the repository has
      // it saved and sends it again later.
      debugPrint('Dua reading not tracked: $error');
    }
    return true;
  }

  /// (Re)creates the one-second clock and the draft timer, or leaves neither
  /// running while the tracker is paused, stopped or disposed.
  void _schedule() {
    _ticker?.cancel();
    _saver?.cancel();
    _ticker = null;
    _saver = null;
    if (_startedAt == null || _paused || _completed || _disposed) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    final every = saveEvery;
    if (every != null) {
      _saver = Timer.periodic(every, (_) => unawaited(saveDraft()));
    }
  }

  void _tick() {
    if (_rollOverAtMidnight()) return;
    final seconds = elapsedSeconds;
    if (seconds == _shownSeconds) return;
    _shownSeconds = seconds;
    _publishLiveProgress(seconds);
    notifyListeners();
  }

  /// Shows the running visit on the Amol cards, which is what makes the Dua
  /// point appear as the fifth minute is reached rather than once the report
  /// has been sent. Published only when the shown minute changes: the cards
  /// rebuild on it.
  void _publishLiveProgress(int seconds) {
    final startedAt = _startedAt;
    final unreported = seconds - _reported;
    if (startedAt == null || unreported < minSeconds) return;
    final minute = unreported ~/ 60;
    if (minute == _publishedMinute) return;
    _publishedMinute = minute;
    _repository.publishReadingProgress(
      sessionId: _reportId,
      duaId: duaId,
      seconds: unreported,
      date: startedAt,
    );
  }

  /// Midnight, mid-visit: reports the time that belongs to the day which has
  /// just ended and starts the visit again, from zero, on the new day.
  /// Returns whether that happened.
  ///
  /// The split is on the clock, not on the visit: whatever ran up to
  /// midnight is the old day's, whatever has run since is the new day's, so
  /// neither is ever credited with the other's minutes.
  bool _rollOverAtMidnight() {
    final startedAt = _startedAt;
    if (startedAt == null || _completed) return false;
    final now = _now();
    final midnight = amolTrackingDate(now);
    if (!midnight.isAfter(startedAt)) return false;

    final since = _runningSince;
    final Duration carried;
    if (since != null && since.isBefore(midnight)) {
      // The stopwatch was running through midnight: close it there.
      _banked += midnight.difference(since);
      carried = now.difference(midnight);
    } else {
      // It started after midnight (a resume), or is stopped: everything
      // banked is the old day's and nothing of it is the new day's.
      carried = since == null ? Duration.zero : now.difference(since);
    }
    _runningSince = null;
    // Claims and sends the old day's seconds under the old day's date.
    // Anything below the API's half-minute minimum is dropped, exactly as it
    // would be on leaving the screen.
    unawaited(_report());
    _startedAt = midnight;
    _banked = carried;
    _runningSince = now;
    _reported = 0;
    _shownSeconds = carried.inSeconds;
    _publishedMinute = 0;
    notifyListeners();
    return true;
  }

  /// Moves the time run so far into [_banked] and stops the stopwatch.
  void _bank() {
    final since = _runningSince;
    if (since == null) return;
    _banked += _now().difference(since);
    _runningSince = null;
  }

  void _stopClock() {
    _bank();
    _ticker?.cancel();
    _ticker = null;
    _saver?.cancel();
    _saver = null;
  }
}
