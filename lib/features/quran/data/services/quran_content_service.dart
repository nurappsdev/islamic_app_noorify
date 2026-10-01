import 'quran_offline_database.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuhfatul_muslim/core/network/dio_client.dart';
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

/// Thrown when Quran content is not stored on the device and the server
/// cannot be reached.
class QuranOfflineException implements Exception {
  const QuranOfflineException();
  @override
  String toString() => 'QuranOfflineException';
}

/// Quran content is static, so it is read offline-first: memory, then the
/// on-device database ([QuranOfflineDatabase]), and only then the server,
/// whose response is stored for next time. Once any page of a surah has been
/// fetched, the rest of that surah is downloaded in the background, so every
/// later page (and every later visit, online or not) reads locally.
///
/// Stored content is shown at once; content older than [refreshAfter] is
/// refreshed in the background when the server is reachable, never making
/// the reader wait. Failed requests are never cached, and concurrent readers
/// share in-flight requests. User data (progress, bookmarks, tracking) does
/// not go through here.
class QuranContentService {
  QuranContentService({
    DioClient? client,
    this.persistCache = true,
    QuranOfflineDatabase? database,
  }) : _client = client ?? DioClient(),
       _databaseOverride = database;
  static final shared = QuranContentService();
  final DioClient _client;
  final bool persistCache;
  final QuranOfflineDatabase? _databaseOverride;
  QuranOfflineDatabase get _database =>
      _databaseOverride ?? QuranOfflineDatabase();

  /// How old stored content may get before a background refresh.
  static const refreshAfter = Duration(days: 30);

  /// The most ayahs the server returns per request.
  static const _pageLimit = 300;

  final _cache = <String, Map<String, dynamic>>{};
  final _pending = <String, Future<Map<String, dynamic>>>{};
  final _surahDownloads = <String, Future<void>>{};
  // The retired SharedPreferences copy of this cache: removed on first use.
  static const _legacyCacheKey = 'quran_internal_content_v1';
  bool _legacyCleared = false;

  static String _keyOf(String path, Map<String, Object> query) =>
      '$path?${Uri(queryParameters: query.map((k, v) => MapEntry(k, '$v'))).query}';

  void _remember(String key, Map<String, dynamic> body) {
    _cache.remove(key);
    _cache[key] = body;
    while (_cache.length > 48) {
      _cache.remove(_cache.keys.first);
    }
  }

  Future<void> _clearLegacyCache() async {
    if (_legacyCleared || !persistCache) return;
    _legacyCleared = true;
    try {
      await (await SharedPreferences.getInstance()).remove(_legacyCacheKey);
    } catch (_) {
      /* Only frees space. */
    }
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, Object> query = const {},
  ]) async {
    final key = _keyOf(path, query);
    unawaited(_clearLegacyCache());
    final cached = _cache[key];
    if (cached != null) {
      _remember(key, cached);
      return cached;
    }
    // Stored ranges come back whole, as page 1.
    if (persistCache && (query['page'] == null || query['page'] == 1)) {
      final stored = await _stored(path, query);
      if (stored != null) {
        _remember(key, stored);
        if (!path.contains('/ayahs')) unawaited(_refreshIfStale(path, query));
        return stored;
      }
    }
    return _request(path, query, key);
  }

  /// The stored response for [path] and [query], or null when the device
  /// does not have all of it.
  Future<Map<String, dynamic>?> _stored(
    String path,
    Map<String, Object> query,
  ) async {
    try {
      return await _database.internalResponse(path, query);
    } catch (_) {
      /* SQLite may be unavailable on the current platform. */
      return null;
    }
  }

  /// Fetches from the server, sharing a request already in flight.
  Future<Map<String, dynamic>> _request(
    String path,
    Map<String, Object> query,
    String key,
  ) async {
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
    final Response<Object> response;
    try {
      response = await _client.dio.get<Object>(
        '/quran/$path',
        queryParameters: query,
      );
    } on DioException catch (e) {
      throw switch (e.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => const QuranOfflineException(),
        _ when e.error is SocketException => const QuranOfflineException(),
        _ => e,
      };
    } on SocketException {
      throw const QuranOfflineException();
    }
    final body = response.data;
    if (response.statusCode != 200 ||
        body is! Map<String, dynamic> ||
        body['success'] != true ||
        body['data'] == null) {
      throw const FormatException('Unable to load Quran content');
    }
    if (persistCache) {
      try {
        await _database.cacheInternalResponse(path, body);
      } catch (_) {
        /* Keep the memory copy if SQLite is unavailable. */
      }
    }
    _remember(key, body);
    return body;
  }

  /// Refreshes stored metadata older than [refreshAfter], in the background.
  Future<void> _refreshIfStale(String path, Map<String, Object> query) async {
    try {
      final at = await _database.internalCachedAt(path);
      if (at == null || DateTime.now().difference(at) < refreshAfter) return;
      await _request(path, query, _keyOf(path, query));
    } catch (_) {
      /* Offline or failed: the stored copy stays in use. */
    }
  }

  /// Stores every ayah of [surah] with [translations], once, in the
  /// background. Surahs already complete and recent are skipped; complete
  /// but old ones are refreshed. Never blocks reading.
  Future<void> cacheSurah(int surah, List<int> translations) {
    if (!persistCache) return Future.value();
    final key = '$surah:${translations.join(',')}';
    // A block body: returning the removed future would make it wait on
    // itself.
    return _surahDownloads[key] ??= _cacheSurah(
      surah,
      translations,
    ).whenComplete(() {
      _surahDownloads.remove(key);
    });
  }

  Future<void> _cacheSurah(int surah, List<int> translations) async {
    try {
      final ages = [
        for (final t in translations) await _database.surahCachedAt(surah, t),
      ];
      if (ages.every(
        (at) => at != null && DateTime.now().difference(at) < refreshAfter,
      )) {
        return;
      }
      final meta = await loadSurah(surah);
      var page = 1;
      while (true) {
        final query = <String, Object>{
          'from': 1,
          'to': meta.totalAyah,
          'translations': translations.join(','),
          'withTranslations': true,
          'limit': _pageLimit,
          'page': page,
        };
        // Straight to the server: this is what fills the local copy.
        final body = await _request(
          'surahs/$surah/ayahs',
          query,
          _keyOf('surahs/$surah/ayahs', query),
        );
        final pagination = QuranPagination.fromJson(
          body['meta'] as Map<String, dynamic>? ?? const {},
        );
        if (!pagination.hasNext || pagination.page != page) break;
        page++;
      }
      for (final t in translations) {
        await _database.markSurahCached(surah, t, meta.totalAyah);
      }
    } catch (_) {
      /* Offline or failed: pages still load one by one when reached. */
    }
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
    if (persistCache) {
      final cached = await _stored('surahs/$surah/ayahs', {
        'from': ayah,
        'to': ayah,
        'translations': '$translation',
      });
      if (cached != null) {
        final data = cached['data'] as Map<String, dynamic>;
        return QuranAyah.fromJson(
          (data['ayahs'] as List).single as Map<String, dynamic>,
        );
      }
    }
    return QuranAyah.fromJson(
      (await _get('ayahs/$surah/$ayah', {'translations': translation}))['data']
          as Map<String, dynamic>,
    );
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
    // Once reading starts, keep the whole surah on the device.
    unawaited(cacheSurah(surah, translations));
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
