import '../data/services/quran_content_service.dart';
import 'quran_route_args.dart';

/// Resolves exactly one adjacent Surah. Para readers keep their own bounds.
Future<SurahRouteArgs?> adjacentSurahArgs({
  required QuranContentService service,
  required SurahRouteArgs current,
  required QuranReadingSession session,
  required bool forward,
}) async {
  if (current.paraNumber != null) return null;
  final number = current.surahNo + (forward ? 1 : -1);
  if (number < 1 || number > 114) return null;

  final surah = await service.loadSurah(number);
  if (surah.number != number || surah.totalAyah < 1) {
    throw const FormatException('Invalid adjacent Surah metadata');
  }
  return SurahRouteArgs(
    surahNo: number,
    surahName: surah.name,
    ayahNo: forward ? 1 : surah.totalAyah,
    readingSession: session,
    swipeForward: forward,
  );
}
