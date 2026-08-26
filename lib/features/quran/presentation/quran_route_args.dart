/// Arguments for routes that navigate to a specific surah, carrying the
/// surah name alongside its number so the destination screen can show it
/// immediately (before the surah detail finishes loading).
class SurahRouteArgs {
  const SurahRouteArgs({required this.surahNo, required this.surahName});

  final int surahNo;
  final String surahName;
}
