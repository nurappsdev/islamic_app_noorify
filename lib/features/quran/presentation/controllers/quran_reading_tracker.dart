import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:islami_app_noorify/features/quran/domain/repositories/quran_reading_repository.dart';

/// Tunables of the Quran reading tracker.
abstract final class QuranReadingTrackerConfig {
  /// Shorter sessions (flipping past a page) are not reported.
  static const minSeconds = 5;

  /// The most one report may carry (the API's limit).
  static const maxSeconds = 3600;
}

/// Measures Quran reading and reports it to the backend
/// (`POST /quran/reading/track`), one session at a time.
///
/// A session is one Surah's ayahs read without a jump: turning to the next
/// or previous page extends it, while jumping elsewhere (or into another
/// Surah) reports it and starts a new one. Only foreground time counts —
/// [pause] stops the clock (and reports what was read so far, since a
/// backgrounded app may never come back), [resume] restarts it.
///
/// Time comes from timestamps, not a ticking timer. Each report takes the
/// session's seconds and clears them *before* the request goes out, so no
/// second of reading is ever sent twice — however often, or concurrently,
/// [flush], [pause] and [dispose] run. A failed report is dropped quietly:
/// tracking never gets in the way of reading.
class QuranReadingTracker {
  QuranReadingTracker(
    this._repository, {
    DateTime Function()? now,
    this.minSeconds = QuranReadingTrackerConfig.minSeconds,
    this.maxSeconds = QuranReadingTrackerConfig.maxSeconds,
  }) : _now = now ?? DateTime.now;

  final QuranReadingRepository _repository;
  final DateTime Function() _now;
  final int minSeconds, maxSeconds;

  _Session? _session;

  /// The page on screen, so a session can restart on it after a report.
  ({int surah, int from, int to})? _page;
  bool _paused = false;
  bool _disposed = false;

  /// The reader now shows ayahs [fromAyah]-[toAyah] of [surahNumber].
  void show(int surahNumber, int fromAyah, int toAyah) {
    if (_disposed || fromAyah < 1 || toAyah < fromAyah) return;
    _page = (surah: surahNumber, from: fromAyah, to: toAyah);
    final session = _session;
    if (session != null &&
        session.surah == surahNumber &&
        fromAyah <= session.to + 1 &&
        toAyah >= session.from - 1) {
      session
        ..from = math.min(session.from, fromAyah)
        ..to = math.max(session.to, toAyah);
      return;
    }
    unawaited(flush());
    _session = _Session(surahNumber, fromAyah, toAyah, _now())
      ..start(_paused ? null : _now());
  }

  /// Stops the clock (the app went to the background) and reports the
  /// reading so far.
  Future<void> pause() {
    if (_paused || _disposed) return Future.value();
    _paused = true;
    _session?.stop(_now());
    return flush();
  }

  /// Restarts the clock on the page still on screen.
  void resume() {
    if (!_paused || _disposed) return;
    _paused = false;
    _session?.start(_now());
  }

  /// Reports the current session, if long enough, and starts a fresh one on
  /// the page on screen.
  Future<void> flush() async {
    final session = _session;
    if (session == null) return;
    final now = _now();
    final seconds = session.take(now);
    final page = _page;
    _session = _disposed || page == null
        ? null
        : (_Session(page.surah, page.from, page.to, now)
            ..start(_paused ? null : now));
    if (seconds < minSeconds || !_repository.isSignedIn) return;
    try {
      await _repository.trackReading(
        surahNumber: session.surah,
        fromAyah: session.from,
        toAyah: session.to,
        seconds: math.min(seconds, maxSeconds),
        date: session.startedAt,
      );
    } catch (error) {
      // Reading goes on whatever happens to the report.
      debugPrint('Quran reading not tracked: $error');
    }
  }

  /// Reports the last session and stops for good. Safe to call twice.
  Future<void> dispose() {
    if (_disposed) return Future.value();
    _disposed = true;
    _session?.stop(_now());
    return flush();
  }

  @visibleForTesting
  ({int surah, int from, int to, int seconds})? get debugSession {
    final session = _session;
    if (session == null) return null;
    return (
      surah: session.surah,
      from: session.from,
      to: session.to,
      seconds: session.peek(_now()),
    );
  }
}

/// One run of ayahs and the foreground time spent on it.
class _Session {
  _Session(this.surah, this.from, this.to, this.startedAt);

  final int surah;
  int from, to;

  /// When the session began — its reading day.
  final DateTime startedAt;
  Duration _banked = Duration.zero;
  DateTime? _runningSince;

  void start(DateTime? at) => _runningSince ??= at;

  void stop(DateTime at) {
    final since = _runningSince;
    if (since == null) return;
    _banked += at.difference(since);
    _runningSince = null;
  }

  int peek(DateTime at) {
    final since = _runningSince;
    return (_banked + (since == null ? Duration.zero : at.difference(since)))
        .inSeconds;
  }

  /// The seconds so far; the session then counts from zero.
  int take(DateTime at) {
    final seconds = peek(at);
    _banked = Duration.zero;
    if (_runningSince != null) _runningSince = at;
    return seconds;
  }
}
