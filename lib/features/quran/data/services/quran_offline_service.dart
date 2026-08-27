import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:islami_app_noorify/features/quran/domain/surah_detail.dart';
import 'package:islami_app_noorify/features/quran/domain/surah_summary.dart';

import 'quran_api_service.dart';
import 'quran_offline_database.dart';

/// Offline Quran source: reads Arabic text and the English + Bengali
/// translations from the on-device SQLite database built by
/// [QuranOfflineDownloader]. No network access.
///
/// Per-ayah audio is not part of this source — it is handled separately by
/// `QuranAudioDownloader` (local file if downloaded, otherwise streamed).
class QuranOfflineService implements QuranApiService {
  QuranOfflineService({QuranOfflineDatabase? database})
    : _db = database ?? QuranOfflineDatabase();

  static const _assetMetaPath = 'assets/database/surah_meta.json';

  final QuranOfflineDatabase _db;

  @override
  Future<List<SurahSummary>> loadSurahList() async {
    final rows = await _db.surahMetaRows();
    if (rows.isNotEmpty) {
      return [
        for (final row in rows)
          SurahSummary(
            number: row['number'] as int,
            name: row['name'] as String? ?? '',
            nameArabic: row['name_arabic'] as String? ?? '',
            translation: row['translation'] as String? ?? '',
            revelationPlace: row['revelation_place'] as String? ?? '',
            totalAyah: (row['total_ayah'] as num?)?.toInt() ?? 0,
          ),
      ];
    }
    return _bundledMeta();
  }

  @override
  Future<SurahDetail> loadSurahDetail(int surahNo) async {
    final meta = (await _db.surahMetaRows()).where(
      (row) => row['number'] == surahNo,
    );
    final metaRow = meta.isEmpty ? null : meta.first;

    final rows = await _db.surahTextRows(surahNo);
    if (rows.isEmpty) {
      throw const FormatException('Surah not found in offline database');
    }

    return SurahDetail(
      number: surahNo,
      name: metaRow?['name'] as String? ?? '',
      nameArabic: metaRow?['name_arabic'] as String? ?? '',
      translation: metaRow?['translation'] as String? ?? '',
      revelationPlace: metaRow?['revelation_place'] as String? ?? '',
      totalAyah: (metaRow?['total_ayah'] as num?)?.toInt() ?? rows.length,
      arabicAyahs: [for (final row in rows) row['text_ar'] as String? ?? ''],
      englishAyahs: [for (final row in rows) row['text_en'] as String? ?? ''],
      bengaliAyahs: [for (final row in rows) row['text_bn'] as String? ?? ''],
    );
  }

  Future<List<SurahSummary>> _bundledMeta() async {
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
  }
}
