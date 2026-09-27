import '../../domain/surah_detail.dart';
import '../../domain/surah_summary.dart';
import 'quran_content_service.dart';

abstract interface class QuranApiService {
  Future<List<SurahSummary>> loadSurahList();
  Future<SurahDetail> loadSurahDetail(int surahNo);
}

/// Adapter for the existing offline downloader and legacy ayah widgets.
/// Interactive reading uses bounded ranges through QuranContentService.
class InternalQuranApiService implements QuranApiService {
  InternalQuranApiService({QuranContentService? content})
    : _content = content ?? QuranContentService.shared;
  final QuranContentService _content;
  @override
  Future<List<SurahSummary>> loadSurahList() => _content.loadSurahs();
  @override
  Future<SurahDetail> loadSurahDetail(int surahNo) async {
    final meta = await _content.loadSurah(surahNo);
    final ayahs = await _content.loadRange(
      surahNo,
      from: 1,
      to: meta.totalAyah,
      translations: [20, 161],
    );
    return SurahDetail(
      number: meta.number,
      name: meta.name,
      nameArabic: meta.nameArabic,
      translation: meta.translation,
      revelationPlace: meta.revelationPlace,
      totalAyah: meta.totalAyah,
      arabicAyahs: [for (final a in ayahs) a.textArabic],
      englishAyahs: [for (final a in ayahs) a.translations[20]?.text ?? ''],
      bengaliAyahs: [for (final a in ayahs) a.translations[161]?.text ?? ''],
    );
  }
}
