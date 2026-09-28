import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where one Mushaf page begins.
class QuranPageStart {
  const QuranPageStart({
    required this.page,
    required this.surahNo,
    required this.ayahNo,
    required this.paraNo,
  });

  final int page, surahNo, ayahNo, paraNo;
}

/// The first ayah of each of the 604 Mushaf pages, bundled as
/// `assets/database/quran_pages.json` (generated from the Quran API's
/// per-ayah page numbers), so pages can be browsed offline.
class QuranPageIndex {
  QuranPageIndex._();

  static const _asset = 'assets/database/quran_pages.json';
  static Future<List<QuranPageStart>>? _pages;

  static Future<List<QuranPageStart>> load({AssetBundle? bundle}) =>
      _pages ??= _read(bundle ?? rootBundle).catchError((Object error) {
        _pages = null;
        throw error;
      });

  /// Replaces the loaded index, for widget tests.
  @visibleForTesting
  static void debugSeed(List<QuranPageStart> pages) =>
      _pages = Future.value(pages);

  static Future<List<QuranPageStart>> _read(AssetBundle bundle) async {
    final raw = jsonDecode(await bundle.loadString(_asset)) as List;
    return [
      for (final entry in raw.cast<Map<String, dynamic>>())
        QuranPageStart(
          page: (entry['page'] as num).toInt(),
          surahNo: (entry['surah'] as num).toInt(),
          ayahNo: (entry['ayah'] as num).toInt(),
          paraNo: (entry['para'] as num).toInt(),
        ),
    ];
  }
}
