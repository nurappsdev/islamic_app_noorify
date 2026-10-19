import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where the Arabic ayah text comes from, one surah at a time, as
/// verse key -> text.
abstract interface class QuranArabicTextSource {
  Future<Map<String, String>> surah(int number);
}

/// The Quran bundled with the app, so any surah reads without the network:
///
/// * `indopak_nastaleeq.json`: the IndoPak Nastaleeq text, the script the
///   bundled IndoPak Nastaleeq font is made for (from quran.com, rebuilt
///   with `dart run tool/build_quran_arabic_asset.dart`). The server's own
///   Arabic is never shown.
/// * `quran_meta.json`: a snapshot of the server's surah metadata and each
///   ayah's page, para and sajdah numbers (rebuilt with
///   `dart run tool/build_quran_meta_asset.dart`).
///
/// Responses come in the server's shape, so they parse the same way.
/// Translations are not bundled: they come from SQLite or the server.
class QuranBundle implements QuranArabicTextSource {
  QuranBundle({this._bundle});
  static final shared = QuranBundle();
  static const arabicAsset = 'assets/quran/indopak_nastaleeq.json';
  static const metaAsset = 'assets/quran/quran_meta.json';

  final AssetBundle? _bundle;

  /// Read once, on first use; a failed read is forgotten so the next one
  /// retries.
  Future<_Quran>? _quran;

  Future<_Quran> _load() => _quran ??= _read().catchError((Object error) {
    _quran = null;
    throw error;
  });

  Future<_Quran> _read() async {
    final bundle = _bundle ?? rootBundle;
    final arabic = await bundle.loadString(arabicAsset);
    final meta = await bundle.loadString(metaAsset);
    // 1.5 MB: decoded and checked off the UI thread.
    return compute(_decode, (arabic, meta));
  }

  @override
  Future<Map<String, String>> surah(int number) async {
    final ayahs = (await _load()).arabic['$number'] ?? const [];
    return {for (final (i, text) in ayahs.indexed) '$number:${i + 1}': text};
  }

  /// Every surah, as the server's `surahs` response lists them.
  Future<List<Map<String, dynamic>>> surahs() async => [
    for (final surah in (await _load()).surahs) {...surah},
  ];

  /// Surah [number], as the server's `surahs/{number}` response gives it.
  Future<Map<String, dynamic>> surahInfo(int number) async {
    final quran = await _load();
    if (number < 1 || number > quran.surahs.length) {
      throw RangeError.range(number, 1, quran.surahs.length, 'surah');
    }
    return {...quran.surahs[number - 1]};
  }

  /// Ayahs [from] to [to] (default: the last) of surah [number], as the
  /// server's `surahs/{number}/ayahs` response gives them, without
  /// translations.
  Future<Map<String, dynamic>> ayahs(
    int number, {
    int from = 1,
    int? to,
  }) async {
    final quran = await _load();
    final surah = await surahInfo(number);
    final arabic = quran.arabic['$number']!;
    final rows = quran.ayahs['$number']!;
    final last = (to ?? arabic.length).clamp(1, arabic.length);
    final first = from.clamp(1, last);
    final ayahs = [
      for (var n = first; n <= last; n++)
        {
          'surahNumber': number,
          'ayahNumber': n,
          'verseKey': '$number:$n',
          'ayahIndex': quran.offsets[number - 1] + n,
          'pageNumber': rows[n - 1][0],
          'paraNumber': rows[n - 1][1],
          'sajdahNumber': rows[n - 1][2],
          'textArabic': arabic[n - 1],
          'translations': const <Object>[],
        },
    ];
    return {
      'success': true,
      'data': {
        'surah': {...surah, 'surahNumber': number},
        'ayahs': ayahs,
      },
      'meta': {
        'page': 1,
        'limit': ayahs.length,
        'total': ayahs.length,
        'totalPage': 1,
      },
    };
  }
}

/// The decoded assets, checked to hold every ayah exactly once.
class _Quran {
  const _Quran(this.surahs, this.arabic, this.ayahs, this.offsets);
  final List<Map<String, dynamic>> surahs;
  final Map<String, List<String>> arabic;

  /// Surah -> each ayah's [page, para, sajdah or null].
  final Map<String, List<List<int?>>> ayahs;

  /// How many ayahs come before each surah.
  final List<int> offsets;
}

const _surahCount = 114, _ayahCount = 6236;

_Quran _decode((String, String) assets) {
  final arabic = {
    for (final MapEntry(:key, :value) in (jsonDecode(assets.$1) as Map).entries)
      key as String: List<String>.from(value as List),
  };
  final meta = jsonDecode(assets.$2) as Map;
  final surahs = [
    for (final raw in meta['surahs'] as List)
      Map<String, dynamic>.from(raw as Map),
  ];
  final ayahs = {
    for (final MapEntry(:key, :value) in (meta['ayahs'] as Map).entries)
      key as String: [
        for (final row in value as List)
          [for (final n in row as List) (n as num?)?.toInt()],
      ],
  };
  if (surahs.length != _surahCount ||
      arabic.length != _surahCount ||
      ayahs.length != _surahCount) {
    throw const FormatException('Bundled Quran: missing surahs');
  }
  final offsets = <int>[];
  var total = 0;
  for (var n = 1; n <= _surahCount; n++) {
    final count = (surahs[n - 1]['ayahCount'] as num?)?.toInt();
    final text = arabic['$n'], rows = ayahs['$n'];
    if (surahs[n - 1]['number'] != n ||
        count == null ||
        text?.length != count ||
        rows?.length != count ||
        text!.any((t) => t.trim().isEmpty) ||
        rows!.any((r) => r.length != 3 || r[0] == null || r[1] == null)) {
      throw FormatException('Bundled Quran: surah $n is incomplete');
    }
    offsets.add(total);
    total += count;
  }
  if (total != _ayahCount) {
    throw FormatException('Bundled Quran: $total of $_ayahCount ayahs');
  }
  return _Quran(surahs, arabic, ayahs, offsets);
}
