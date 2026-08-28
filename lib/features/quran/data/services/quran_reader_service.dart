import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:islami_app_noorify/features/quran/domain/juz_summary.dart';
import 'package:islami_app_noorify/features/quran/domain/reciter.dart';
import 'package:islami_app_noorify/features/quran/domain/verse_item.dart';

/// Free, keyless Quran Foundation API: https://api.quran.com/api/v4
abstract interface class QuranReaderService {
  Future<List<JuzSummary>> loadJuzList();

  Future<List<VerseItem>> loadVersesByJuz(int juzNumber);

  Future<List<Reciter>> loadReciters();

  Future<String> loadAyahAudioUrl(int recitationId, String verseKey);

  /// Every ayah audio file for a whole surah in one request, as
  /// `(verseKey, absoluteUrl)` pairs. Used to download a surah for offline use.
  Future<List<({String verseKey, String url})>> loadChapterAudioFiles(
    int recitationId,
    int surahNo,
  );

  Future<String> loadTafsir(int tafsirResourceId, String verseKey);

  /// Every ayah of one surah for a translation [resourceId], as ayah number ->
  /// plain text (HTML/footnote tags stripped). Used to download an edition.
  Future<Map<int, String>> loadChapterTranslation(int resourceId, int surahNo);
}

class QuranComReaderService implements QuranReaderService {
  QuranComReaderService({http.Client? client})
    : _client = client ?? http.Client();

  static const _host = 'api.quran.com';
  static const _translationId = '20'; // Saheeh International (English)

  final http.Client _client;

  @override
  Future<List<JuzSummary>> loadJuzList() async {
    final uri = Uri.https(_host, '/api/v4/juzs');
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw const FormatException('Failed to load juz list');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['juzs'] is! List) {
      throw const FormatException('Invalid juz list response');
    }
    final seen = <int>{};
    final juzs = <JuzSummary>[];
    for (final raw in (body['juzs'] as List)) {
      final juz = JuzSummary.fromJson(raw as Map<String, dynamic>);
      if (seen.add(juz.number)) juzs.add(juz);
    }
    juzs.sort((a, b) => a.number.compareTo(b.number));
    return juzs;
  }

  @override
  Future<List<VerseItem>> loadVersesByJuz(int juzNumber) {
    return _loadVerses('/api/v4/verses/by_juz/$juzNumber', perPage: 320);
  }

  @override
  Future<List<Reciter>> loadReciters() async {
    final uri = Uri.https(_host, '/api/v4/resources/recitations', {
      'language': 'en',
    });
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw const FormatException('Failed to load reciters');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['recitations'] is! List) {
      throw const FormatException('Invalid reciters response');
    }
    final reciters = [
      for (final raw in (body['recitations'] as List))
        Reciter.fromJson(raw as Map<String, dynamic>),
    ];
    reciters.sort((a, b) => a.name.compareTo(b.name));
    return reciters;
  }

  @override
  Future<String> loadAyahAudioUrl(int recitationId, String verseKey) async {
    final uri = Uri.https(
      _host,
      '/api/v4/recitations/$recitationId/by_ayah/$verseKey',
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw const FormatException('Failed to load ayah audio');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['audio_files'] is! List) {
      throw const FormatException('Invalid ayah audio response');
    }
    final files = body['audio_files'] as List;
    if (files.isEmpty) {
      throw const FormatException('No audio available for this ayah');
    }
    final relativeUrl = (files.first as Map<String, dynamic>)['url'] as String;
    return _absoluteAudioUrl(relativeUrl);
  }

  @override
  Future<List<({String verseKey, String url})>> loadChapterAudioFiles(
    int recitationId,
    int surahNo,
  ) async {
    final uri = Uri.https(
      _host,
      '/api/v4/recitations/$recitationId/by_chapter/$surahNo',
      {'per_page': '300'},
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw const FormatException('Failed to load chapter audio');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['audio_files'] is! List) {
      throw const FormatException('Invalid chapter audio response');
    }
    return [
      for (final raw in (body['audio_files'] as List))
        if (raw is Map<String, dynamic> &&
            raw['verse_key'] is String &&
            raw['url'] is String)
          (
            verseKey: raw['verse_key'] as String,
            url: _absoluteAudioUrl(raw['url'] as String),
          ),
    ];
  }

  static String _absoluteAudioUrl(String url) =>
      url.startsWith('http') ? url : 'https://verses.quran.com/$url';

  @override
  Future<String> loadTafsir(int tafsirResourceId, String verseKey) async {
    final uri = Uri.https(
      _host,
      '/api/v4/tafsirs/$tafsirResourceId/by_ayah/$verseKey',
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw const FormatException('Failed to load tafsir');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['tafsir'] is! Map) {
      throw const FormatException('Invalid tafsir response');
    }
    final tafsir = body['tafsir'] as Map<String, dynamic>;
    final rawHtml = tafsir['text'] as String? ?? '';
    return rawHtml.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  @override
  Future<Map<int, String>> loadChapterTranslation(
    int resourceId,
    int surahNo,
  ) async {
    final uri = Uri.https(_host, '/api/v4/quran/translations/$resourceId', {
      'chapter_number': '$surahNo',
    });
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw const FormatException('Failed to load chapter translation');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['translations'] is! List) {
      throw const FormatException('Invalid chapter translation response');
    }
    final list = body['translations'] as List;
    final result = <int, String>{};
    for (var i = 0; i < list.length; i++) {
      final raw = list[i];
      if (raw is! Map<String, dynamic>) continue;
      final text = (raw['text'] as String? ?? '')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();
      // The array is in ayah order with no verse number of its own.
      result[i + 1] = text;
    }
    if (result.isEmpty) {
      throw const FormatException('Empty chapter translation');
    }
    return result;
  }

  Future<List<VerseItem>> _loadVerses(
    String path, {
    required int perPage,
  }) async {
    final uri = Uri.https(_host, path, {
      'words': 'false',
      'fields': 'text_uthmani',
      'translations': _translationId,
      'per_page': '$perPage',
    });
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw const FormatException('Failed to load verses');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['verses'] is! List) {
      throw const FormatException('Invalid verses response');
    }
    return [
      for (final raw in (body['verses'] as List))
        VerseItem.fromJson(raw as Map<String, dynamic>),
    ];
  }
}
