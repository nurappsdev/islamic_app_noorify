import 'package:islami_app_noorify/features/quran/domain/translation_edition.dart';

import 'quran_offline_database.dart';
import 'quran_reader_service.dart';

/// Downloads one whole translation edition (all 114 surahs) from
/// `api.quran.com` into [QuranOfflineDatabase.translation_text].
///
/// Resumable: each surah is committed as it arrives, so an interrupted run
/// continues from the first surah that is not yet complete. Every write
/// replaces on a UNIQUE key, so retries never create duplicate rows.
class QuranTranslationDownloader {
  QuranTranslationDownloader({
    QuranReaderService? readerService,
    QuranOfflineDatabase? database,
  }) : _reader = readerService ?? QuranComReaderService(),
       _db = database ?? QuranOfflineDatabase();

  final QuranReaderService _reader;
  final QuranOfflineDatabase _db;

  Stream<QuranSetupProgress> downloadEdition(
    TranslationEdition edition,
  ) async* {
    final resourceId = edition.resourceId;
    if (resourceId == null) {
      throw const QuranSetupException('This translation is already built in.');
    }
    const total = QuranOfflineDatabase.surahCount;
    final done = await _db.completedEditionSurahIds(edition.id);
    yield QuranSetupProgress(QuranSetupPhase.building, done.length, total);

    for (var surahNo = 1; surahNo <= total; surahNo++) {
      if (done.contains(surahNo)) continue;
      final Map<int, String> ayahText;
      try {
        ayahText = await _reader.loadChapterTranslation(resourceId, surahNo);
      } catch (_) {
        throw QuranSetupException(
          'Download interrupted at surah $surahNo. Check your connection and '
          'resume.',
        );
      }
      if (ayahText.isEmpty) {
        throw QuranSetupException(
          'No translation available for surah $surahNo.',
        );
      }
      await _db.upsertEditionSurahText(edition.id, surahNo, ayahText);
      yield QuranSetupProgress(QuranSetupPhase.building, surahNo, total);
    }

    await _db.upsertEditionMeta(
      editionId: edition.id,
      name: edition.name,
      language: edition.languageName,
      status: 'complete',
    );
  }
}
