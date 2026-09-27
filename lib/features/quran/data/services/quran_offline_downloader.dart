import 'quran_content_service.dart';
import 'quran_api_service.dart';
import 'quran_offline_database.dart';

/// Builds the offline Quran database by fetching Arabic text plus the English
/// and Bengali translations from the app's existing Quran API
/// (`internal Quran API`, wrapped by [InternalQuranApiService]) and writing them
/// into [QuranOfflineDatabase].
///
/// Resumable: surah metadata and each surah's ayahs are committed as they
/// arrive, so an interrupted run continues from the first surah that is not
/// yet complete. Every write replaces on a UNIQUE key, so retries never create
/// duplicate rows.
class QuranOfflineDownloader {
  QuranOfflineDownloader({
    QuranApiService? apiService,
    QuranOfflineDatabase? database,
  }) : _api = apiService ?? InternalQuranApiService(),
       _db = database ?? QuranOfflineDatabase();

  final QuranApiService _api;
  final QuranOfflineDatabase _db;

  Stream<QuranSetupProgress> downloadAllText() async* {
    yield const QuranSetupProgress(QuranSetupPhase.reading, 0, 1);

    await _writeSurahMeta();
    yield const QuranSetupProgress(QuranSetupPhase.reading, 1, 1);

    await QuranContentService.shared.loadParas();
    await QuranContentService.shared.loadTranslations();
    final counts = {
      for (final row in await _db.surahMetaRows())
        row['number'] as int: row['total_ayah'] as int,
    };
    final completed = await _db.completedSurahIds();
    final done = <int>{};
    for (final number in completed) {
      final cached = await _db.internalResponse('surahs/$number/ayahs', {
        'from': 1,
        'to': counts[number] ?? 0,
        'translations': '20,161',
      });
      if (cached != null) done.add(number);
    }
    const total = QuranOfflineDatabase.surahCount;
    yield QuranSetupProgress(QuranSetupPhase.building, done.length, total);

    for (var surahNo = 1; surahNo <= total; surahNo++) {
      if (done.contains(surahNo)) continue;
      try {
        final detail = await _api.loadSurahDetail(surahNo);
        if (detail.arabicAyahs.isEmpty) {
          throw const FormatException('empty surah');
        }
        await _db.upsertSurahText(surahNo, [
          for (var i = 0; i < detail.arabicAyahs.length; i++)
            {
              'surah_id': surahNo,
              'ayah_number': i + 1,
              'text_ar': detail.arabicAyahs[i],
              'text_en': i < detail.englishAyahs.length
                  ? detail.englishAyahs[i]
                  : null,
              'text_bn': i < detail.bengaliAyahs.length
                  ? detail.bengaliAyahs[i]
                  : '',
            },
        ]);
      } catch (_) {
        throw QuranSetupException(
          'Download interrupted at surah $surahNo. Check your connection and '
          'resume.',
        );
      }
      yield QuranSetupProgress(QuranSetupPhase.building, surahNo, total);
    }
    await _db.cacheInternalResponse('offline-complete-v1', {
      'success': true,
      'data': true,
    });
  }

  Future<void> _writeSurahMeta() async {
    final list = await _api.loadSurahList();
    if (list.length < QuranOfflineDatabase.surahCount) {
      throw const QuranSetupException('Could not load the surah list.');
    }
    await _db.upsertSurahMeta([
      for (final s in list)
        {
          'number': s.number,
          'name': s.name,
          'name_arabic': s.nameArabic,
          'translation': s.translation,
          'revelation_place': s.revelationPlace,
          'total_ayah': s.totalAyah,
        },
    ]);
  }
}
