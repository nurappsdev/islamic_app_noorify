import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:islami_app_noorify/features/quran/domain/surah_summary.dart';

import 'quran_api_service.dart';
import 'quran_offline_database.dart';

/// Builds the offline Quran database by fetching Arabic text plus the English
/// and Bengali translations from the app's existing Quran API
/// (`quranapi.pages.dev`, wrapped by [QuranApiPagesService]) and writing them
/// into [QuranOfflineDatabase].
///
/// Resumable: surah metadata and each surah's ayahs are committed as they
/// arrive, so an interrupted run continues from the first surah that is not
/// yet complete. Every write replaces on a UNIQUE key, so retries never create
/// duplicate rows.
class QuranOfflineDownloader {
  QuranOfflineDownloader({QuranApiService? apiService, QuranOfflineDatabase? database})
    : _api = apiService ?? QuranApiPagesService(),
      _db = database ?? QuranOfflineDatabase();

  static const _assetMetaPath = 'assets/database/surah_meta.json';

  final QuranApiService _api;
  final QuranOfflineDatabase _db;

  Stream<QuranSetupProgress> downloadAllText() async* {
    yield const QuranSetupProgress(QuranSetupPhase.reading, 0, 1);

    if (await _db.surahMetaCount() < QuranOfflineDatabase.surahCount) {
      await _writeSurahMeta();
    }
    yield const QuranSetupProgress(QuranSetupPhase.reading, 1, 1);

    final done = await _db.completedSurahIds();
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
  }

  Future<void> _writeSurahMeta() async {
    List<SurahSummary> list;
    try {
      list = await _api.loadSurahList();
    } catch (_) {
      list = await _bundledMeta();
    }
    if (list.length < QuranOfflineDatabase.surahCount) {
      final bundled = await _bundledMeta();
      if (bundled.length > list.length) list = bundled;
    }
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

  Future<List<SurahSummary>> _bundledMeta() async {
    try {
      final raw = await rootBundle.loadString(_assetMetaPath);
      return [
        for (final entry
            in (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
          SurahSummary(
            number: (entry['number'] as num).toInt(),
            name: entry['name'] as String? ?? '',
            nameArabic: entry['nameArabic'] as String? ?? '',
            translation: entry['translation'] as String? ?? '',
            revelationPlace: entry['revelationPlace'] as String? ?? '',
            totalAyah: (entry['totalAyah'] as num?)?.toInt() ?? 0,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }
}
