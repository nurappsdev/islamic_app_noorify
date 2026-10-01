import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuhfatul_muslim/core/network/dio_client.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_content_service.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_offline_database.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_design.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

import 'quran_content_test.dart' show Adapter, ok;

/// A small surah (7 ayahs) served the way the Quran API serves them.
const _ayahCount = 7;

Map<String, Object?> _surahMeta(int number) => {
  'number': number,
  'surahNumber': number,
  'nameEnglish': 'Surah $number',
  'nameArabic': 'سورة',
  'nameBangla': 'সূরা',
  'ayahCount': _ayahCount,
  'revelationType': 'meccan',
  'bismillahPre': true,
  'pages': [1],
};

Map<String, Object?> _ayah(int surah, int n, int resource) => {
  'surahNumber': surah,
  'ayahNumber': n,
  'verseKey': '$surah:$n',
  'ayahIndex': n,
  'paraNumber': 1,
  'pageNumber': 1,
  'textArabic': 'آية $n',
  'translations': [
    {
      'resourceId': resource,
      'languageCode': resource == 161 ? 'bn' : 'en',
      'name': 'Edition $resource',
      'text': 'Translation $resource of $surah:$n',
      'textPlain': 'Translation $resource of $surah:$n',
    },
  ],
};

/// Serves surah metadata and ayah ranges (honouring from/to/limit/page).
Map<String, Object?> _serve(RequestOptions request) {
  final parts = request.path.split('/');
  final surah = int.parse(parts[parts.indexOf('surahs') + 1]);
  if (!request.path.endsWith('/ayahs')) return ok(_surahMeta(surah));
  final q = request.queryParameters;
  final from = int.parse('${q['from']}');
  final to = int.parse('${q['to']}');
  final limit = int.parse('${q['limit'] ?? 50}');
  final page = int.parse('${q['page'] ?? 1}');
  final resource = int.parse('${q['translations']}'.split(',').first);
  final all = [for (var n = from; n <= to; n++) _ayah(surah, n, resource)];
  final slice = all.skip((page - 1) * limit).take(limit).toList();
  return ok(
    {'surah': _surahMeta(surah), 'ayahs': slice},
    meta: {
      'page': page,
      'limit': limit,
      'total': all.length,
      'totalPage': (all.length / limit).ceil(),
    },
  );
}

QuranContentService _service(Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
    ..httpClientAdapter = adapter;
  // A fresh service has an empty memory cache, as after an app restart.
  return QuranContentService(client: DioClient(dio: dio));
}

/// A server that cannot be reached.
Adapter _offline() => Adapter(
  (request) => throw DioException(
    requestOptions: request,
    type: DioExceptionType.connectionError,
  ),
);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await QuranOfflineDatabase().delete();
  });
  tearDownAll(() => QuranOfflineDatabase().delete());

  test('a surah read once opens again without the network', () async {
    final online = Adapter(_serve);
    final first = _service(online);
    final page = await first.loadAyahs(1, from: 1, to: 3);
    expect(page.ayahs.map((a) => a.ayahNumber), [1, 2, 3]);
    // Reading any page stores the whole surah in the background.
    await first.cacheSurah(1, const [161]);
    expect(await QuranOfflineDatabase().surahCachedAt(1, 161), isNotNull);

    // After a restart, every page of the surah (and its metadata) is local.
    final again = Adapter(_serve);
    final second = _service(again);
    final meta = await second.loadSurah(1);
    final rest = await second.loadAyahs(1, from: 4, to: 7);
    expect(meta.totalAyah, _ayahCount);
    expect(rest.ayahs.map((a) => a.ayahNumber), [4, 5, 6, 7]);
    expect(rest.ayahs.first.translations[161]?.text, contains('1:4'));
    expect(again.requests, isEmpty);
  });

  test('cached surahs read offline; an uncached one reports offline', () async {
    final first = _service(Adapter(_serve));
    await first.loadAyahs(1, from: 1, to: 7);
    await first.cacheSurah(1, const [161]);

    final offline = _offline();
    final reader = _service(offline);
    final page = await reader.loadAyahs(1, from: 2, to: 5);
    expect(page.ayahs.map((a) => a.ayahNumber), [2, 3, 4, 5]);
    final single = await reader.loadAyah(1, 6);
    expect(single.verseKey, '1:6');

    await expectLater(
      reader.loadAyahs(3, from: 1, to: 3),
      throwsA(isA<QuranOfflineException>()),
    );
    await expectLater(
      reader.loadSurah(3),
      throwsA(isA<QuranOfflineException>()),
    );
  });

  test('another translation is fetched once, then kept with the ayahs', () async {
    final server = Adapter(_serve);
    final service = _service(server);
    await service.loadAyahs(1, from: 1, to: 7);
    await service.cacheSurah(1, const [161]);
    final english = await service.loadAyahs(
      1,
      from: 1,
      to: 7,
      translations: const [20],
    );
    await service.cacheSurah(1, const [20]);
    expect(english.ayahs.first.translations[20]?.text, contains('1:1'));

    // Both editions are now stored for every ayah.
    final offline = _service(_offline());
    for (final resource in [161, 20]) {
      final page = await offline.loadAyahs(
        1,
        from: 1,
        to: 7,
        translations: [resource],
      );
      expect(page.ayahs, hasLength(_ayahCount));
      expect(page.ayahs.last.translations[resource], isNotNull);
    }
  });

  test('stale metadata shows at once and refreshes in the background', () async {
    await _service(Adapter(_serve)).loadSurah(1);
    final db = await QuranOfflineDatabase().open();
    await db.update('internal_quran_meta', {'cached_at': 0});

    final server = Adapter(_serve);
    final meta = await _service(server).loadSurah(1);
    expect(meta.number, 1);
    // Returned from storage first; the refresh follows without being awaited.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(server.requests.map((r) => r.path), ['/quran/surahs/1']);
    final at = await QuranOfflineDatabase().internalCachedAt('surahs/1');
    expect(DateTime.now().difference(at!).inMinutes, 0);
  });

  test('a new content version drops the old reading cache', () async {
    final service = _service(Adapter(_serve));
    await service.loadAyahs(1, from: 1, to: 7);
    await service.cacheSurah(1, const [161]);
    final db = await QuranOfflineDatabase().open();
    // As if these rows were written by an older content version.
    await db.update('internal_quran_state', {
      'value': '${QuranOfflineDatabase.contentVersion - 1}',
    }, where: "key = 'content_version'");
    await db.insert('internal_quran_meta', {
      'cache_key': 'offline-complete-v1',
      'body': '{}',
    });
    await db.close();

    expect(await QuranOfflineDatabase().surahCachedAt(1, 161), isNull);
    final reopened = await QuranOfflineDatabase().open();
    expect(
      await reopened.query('internal_quran_ayahs'),
      isEmpty,
      reason: 'old ayahs are dropped',
    );
    expect(
      await reopened.query(
        'internal_quran_meta',
        where: "cache_key = 'offline-complete-v1'",
      ),
      hasLength(1),
      reason: 'the full offline download is not part of the reading cache',
    );
  });

  testWidgets('the retry view explains an offline, never-downloaded surah', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => LanguageBloc(
          initialLanguage: AppLanguage.english,
          persist: (_) async {},
        ),
        child: MaterialApp(
          home: Scaffold(body: QuranRetry(offline: true, onRetry: () {})),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('quran-offline-message')), findsOneWidget);
    expect(find.textContaining("You're offline"), findsOneWidget);
  });
}
