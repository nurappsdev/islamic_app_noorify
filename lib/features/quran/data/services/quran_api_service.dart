import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:islami_app_noorify/features/quran/domain/surah_detail.dart';
import 'package:islami_app_noorify/features/quran/domain/surah_summary.dart';

/// Free, keyless Quran API: https://quranapi.pages.dev
abstract interface class QuranApiService {
  Future<List<SurahSummary>> loadSurahList();

  Future<SurahDetail> loadSurahDetail(int surahNo);
}

class QuranApiPagesService implements QuranApiService {
  QuranApiPagesService({http.Client? client}) : _client = client ?? http.Client();

  static const _host = 'quranapi.pages.dev';

  final http.Client _client;

  @override
  Future<List<SurahSummary>> loadSurahList() async {
    final uri = Uri.https(_host, '/api/surah.json');
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw const FormatException('Failed to load surah list');
    }
    final body = jsonDecode(response.body);
    if (body is! List) {
      throw const FormatException('Invalid surah list response');
    }
    return [
      for (var i = 0; i < body.length; i++)
        SurahSummary.fromJson(i + 1, body[i] as Map<String, dynamic>),
    ];
  }

  @override
  Future<SurahDetail> loadSurahDetail(int surahNo) async {
    final uri = Uri.https(_host, '/api/$surahNo.json');
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw const FormatException('Failed to load surah detail');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Invalid surah detail response');
    }
    return SurahDetail.fromJson(body);
  }
}
