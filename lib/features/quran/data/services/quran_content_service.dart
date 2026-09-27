import 'quran_offline_database.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islami_app_noorify/core/network/dio_client.dart';
import '../../domain/surah_summary.dart';
import '../../domain/juz_summary.dart';
import '../../domain/quran_ayah.dart';
import '../../domain/translation_edition.dart';

class QuranAyahPage {
  const QuranAyahPage({
    required this.surah,
    required this.ayahs,
    required this.pagination,
    required this.bismillahPre,
    required this.pages,
  });
  final SurahSummary surah;
  final List<QuranAyah> ayahs;
  final QuranPagination pagination;
  final bool bismillahPre;
  final List<int> pages;
}

/// All internal Quran requests share the application's configured client.
/// Successful responses have a bounded memory/disk cache. Failed requests are
/// never cached, and concurrent readers share in-flight requests.
class QuranContentService {
  QuranContentService({DioClient? client, this.persistCache = true})
    : _client = client ?? DioClient();
  static final shared = QuranContentService();
  final DioClient _client;
  final bool persistCache;
  final _cache = <String, Map<String, dynamic>>{};
  final _pending = <String, Future<Map<String, dynamic>>>{};
  static const _cacheKey = 'quran_internal_content_v1';
  bool _restored = false;

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, Object> query = const {},
  ]) async {
    final key =
        '$path?${Uri(queryParameters: query.map((k, v) => MapEntry(k, '$v'))).query}';
    if (!_restored && persistCache) {
      _restored = true;
      try {
        final raw = (await SharedPreferences.getInstance()).getString(
          _cacheKey,
        );
        if (raw != null) {
          final saved = jsonDecode(raw) as Map<String, dynamic>;
          for (final entry in saved.entries) {
            _cache.putIfAbsent(
              entry.key,
              () => entry.value as Map<String, dynamic>,
            );
          }
        }
      } catch (_) {
        /* A cache failure must not block reading. */
      }
    }
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }
    if (persistCache && (query['page'] == null || query['page'] == 1)) {
      try {
        final saved = await QuranOfflineDatabase().internalResponse(
          path,
          query,
        );
        if (saved != null) return saved;
      } catch (_) {
        /* SQLite may be unavailable on the current platform. */
      }
    }
    final pending = _pending[key];
    if (pending != null) return pending;
    final request = _fetch(path, query, key);
    _pending[key] = request;
    try {
      return await request;
    } finally {
      _pending.remove(key);
    }
  }

  Future<Map<String, dynamic>> _fetch(
    String path,
    Map<String, Object> query,
    String key,
  ) async {
    final response = await _client.dio.get<Object>(
      '/quran/$path',
      queryParameters: query,
    );
    final body = response.data;
    if (response.statusCode != 200 ||
        body is! Map<String, dynamic> ||
        body['success'] != true ||
        body['data'] == null) {
      throw const FormatException('Unable to load Quran content');
    }
    if (persistCache) {
      try {
        await QuranOfflineDatabase().cacheInternalResponse(path, body);
      } catch (_) {
        /* Keep the memory/disk fallback if SQLite is unavailable. */
      }
    }
    _cache[key] = body;
    while (_cache.length > 48) {
      _cache.remove(_cache.keys.first);
    }
    if (persistCache) {
      try {
        await (await SharedPreferences.getInstance()).setString(
          _cacheKey,
          jsonEncode(_cache),
        );
      } catch (_) {
        /* Reading remains available when storage is full. */
      }
    }
    return body;
  }

  Future<List<SurahSummary>> loadSurahs() async {
    final body = await _get('surahs');
    return [
      for (final raw in body['data'] as List)
        SurahSummary.fromInternalJson(raw as Map<String, dynamic>),
    ];
  }

  Future<SurahSummary> loadSurah(int number) async =>
      SurahSummary.fromInternalJson(
        (await _get('surahs/$number'))['data'] as Map<String, dynamic>,
      );
  Future<List<JuzSummary>> loadParas() async => [
    for (final raw in (await _get('paras'))['data'] as List)
      JuzSummary.fromInternalJson(raw as Map<String, dynamic>),
  ];
  Future<JuzSummary> loadPara(int number) async => JuzSummary.fromInternalJson(
    (await _get('paras/$number'))['data'] as Map<String, dynamic>,
  );
  Future<List<TranslationEdition>> loadTranslations() async => [
    for (final raw in (await _get('translations'))['data'] as List)
      TranslationEdition.fromJson(raw as Map<String, dynamic>),
  ];

  Future<QuranAyah> loadAyah(
    int surah,
    int ayah, {
    int translation = 161,
  }) async {
    try {
      return QuranAyah.fromJson(
        (await _get('ayahs/$surah/$ayah', {
              'translations': translation,
            }))['data']
            as Map<String, dynamic>,
      );
    } catch (_) {
      if (persistCache) {
        final cached = await QuranOfflineDatabase().internalResponse(
          'surahs/$surah/ayahs',
          {'from': ayah, 'to': ayah, 'translations': '$translation'},
        );
        if (cached != null) {
          final data = cached['data'] as Map<String, dynamic>;
          return QuranAyah.fromJson(
            (data['ayahs'] as List).single as Map<String, dynamic>,
          );
        }
      }
      rethrow;
    }
  }

  Future<QuranAyahPage> loadAyahs(
    int surah, {
    required int from,
    required int to,
    List<int> translations = const [161],
    int page = 1,
  }) async {
    final body = await _get('surahs/$surah/ayahs', {
      'from': from,
      'to': to,
      'translations': translations.join(','),
      'withTranslations': true,
      'page': page,
    });
    final data = body['data'] as Map<String, dynamic>;
    final meta = data['surah'] as Map<String, dynamic>;
    return QuranAyahPage(
      surah: SurahSummary.fromInternalJson(meta),
      ayahs: [
        for (final raw in data['ayahs'] as List)
          QuranAyah.fromJson(raw as Map<String, dynamic>),
      ],
      pagination: QuranPagination.fromJson(
        body['meta'] as Map<String, dynamic>? ?? const {},
      ),
      bismillahPre: meta['bismillahPre'] as bool? ?? false,
      pages: [for (final p in meta['pages'] as List? ?? []) (p as num).toInt()],
    );
  }

  /// Follows server pagination within a bounded range, including APIs which
  /// cap the limit below the requested range size.
  Future<List<QuranAyah>> loadRange(
    int surah, {
    required int from,
    required int to,
    List<int> translations = const [161],
  }) async {
    final result = <String, QuranAyah>{};
    var page = 1;
    while (true) {
      final response = await loadAyahs(
        surah,
        from: from,
        to: to,
        translations: translations,
        page: page,
      );
      for (final ayah in response.ayahs) {
        result[ayah.verseKey] = ayah;
      }
      if (!response.pagination.hasNext) break;
      if (response.ayahs.isEmpty || response.pagination.page != page) {
        throw const FormatException('Invalid Quran pagination');
      }
      page++;
    }
    return result.values.toList()
      ..sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));
  }
}
