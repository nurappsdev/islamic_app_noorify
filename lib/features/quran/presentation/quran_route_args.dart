/// Arguments for routes that navigate to a specific surah, carrying the
/// surah name alongside its number so the destination screen can show it
/// immediately (before the surah detail finishes loading).
class QuranReadingSession {
  QuranReadingSession({this.initialElapsed = Duration.zero});

  final Duration initialElapsed;
  final Stopwatch _elapsed = Stopwatch()..start();

  int get elapsedSeconds =>
      initialElapsed.inSeconds + _elapsed.elapsed.inSeconds;
}

class SurahRouteArgs {
  const SurahRouteArgs({
    required this.surahNo,
    required this.surahName,
    this.ayahNo = 1,
    this.endAyah,
    this.paraNumber,
    this.paraStartAyah,
    this.readingSession,
    this.swipeForward,
  });

  final int surahNo;
  final int ayahNo;
  final int? endAyah, paraNumber, paraStartAyah;
  final String surahName;
  final QuranReadingSession? readingSession;

  /// Set only for a swipe across Surah boundaries.
  final bool? swipeForward;

  SurahRouteArgs withReadingSession(QuranReadingSession session) =>
      SurahRouteArgs(
        surahNo: surahNo,
        surahName: surahName,
        ayahNo: ayahNo,
        endAyah: endAyah,
        paraNumber: paraNumber,
        paraStartAyah: paraStartAyah,
        readingSession: session,
        swipeForward: swipeForward,
      );
}
