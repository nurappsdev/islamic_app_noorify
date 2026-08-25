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

  Future<String> loadTafsir(int tafsirResourceId, String verseKey);
}

class QuranComReaderService implements QuranReaderService {
  QuranComReaderService({http.Client? client}) : _client = client ?? http.Client();

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
    return 'https://verses.quran.com/$relativeUrl';
  }

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

  Future<List<VerseItem>> _loadVerses(String path, {required int perPage}) async {
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
