import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuhfatul_muslim/core/network/dio_client.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_audio_handler.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_bundle.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_content_service.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_offline_database.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/quran_reading_cubit.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/reciter/reciter_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/surah_audio_download/surah_audio_download_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/surah_playback/surah_playback_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/quran_route_args.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/screens/quran_reading_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

import 'quran_content_test.dart' show Adapter, ok;
import 'quran_playback_test.dart' show TestAudio, TestDownloader;

/// The server's (wrong) Arabic: never shown.
const _serverArabic = 'server text';

/// Serves real surah sizes, each ayah translated as `T surah:ayah`.
Map<String, Object?> _serve(RequestOptions request) {
  final parts = request.path.split('/');
  final number = int.parse(parts[parts.indexOf('surahs') + 1]);
  final meta = {
    'number': number,
    'surahNumber': number,
    'nameSimple': 'Server $number',
    'nameBangla': 'সার্ভার',
    'ayahCount': number == 1 ? 7 : 286,
    'bismillahPre': number != 1,
    'pages': [1],
  };
  if (!request.path.endsWith('/ayahs')) return ok(meta);
  final q = request.queryParameters;
  final from = int.parse('${q['from']}'), to = int.parse('${q['to']}');
  final resource = int.parse('${q['translations']}'.split(',').first);
  final ayahs = [
    for (var n = from; n <= to; n++)
      {
        'surahNumber': number,
        'ayahNumber': n,
        'verseKey': '$number:$n',
        'ayahIndex': n,
        'paraNumber': 1,
        'pageNumber': 1,
        'textArabic': _serverArabic,
        'translations': [
          {'resourceId': resource, 'textPlain': 'T $number:$n'},
        ],
      },
  ];
  return ok(
    {'surah': meta, 'ayahs': ayahs},
    meta: {'page': 1, 'limit': 300, 'total': ayahs.length, 'totalPage': 1},
  );
}

/// A server that cannot be reached.
Adapter _offline() => Adapter(
  (request) => throw DioException(
    requestOptions: request,
    type: DioExceptionType.connectionError,
  ),
);

QuranContentService _service(
  Adapter adapter, {
  QuranBundle? bundle,
  bool persistCache = true,
}) => QuranContentService(
  client: DioClient(
    dio: Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
      ..httpClientAdapter = adapter,
  ),
  persistCache: persistCache,
  bundle: bundle ?? QuranBundle(),
);

/// The real assets, with [edit] applied to the decoded Arabic, failing
/// [failures] times first.
class _EditedAssets extends AssetBundle {
  _EditedAssets(this.edit, {this.failures = 0});
  final void Function(Map<String, dynamic> arabic) edit;
  int failures;

  @override
  Future<ByteData> load(String key) async {
    if (failures > 0) {
      failures--;
      throw FlutterError('Asset $key not ready');
    }
    var text = await rootBundle.loadString(key, cache: false);
    if (key == QuranBundle.arabicAsset) {
      final arabic = jsonDecode(text) as Map<String, dynamic>;
      edit(arabic);
      text = jsonEncode(arabic);
    }
    return ByteData.sublistView(utf8.encode(text));
  }

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) async => parser(await loadString(key));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await QuranOfflineDatabase().delete();
  });
  tearDownAll(() => QuranOfflineDatabase().delete());

  test('a never-opened surah shows its Arabic with the server down', () async {
    final bundle = QuranBundle();
    final offline = _offline();
    final reader = QuranReadingCubit(
      surahNo: 2,
      service: _service(offline, bundle: bundle),
    );
    addTearDown(reader.close);

    await reader.load(from: 255);

    final state = reader.state;
    final arabic = await bundle.surah(2);
    // Mushaf page 42 holds 2:253 to 2:256.
    expect(state.ayahs.map((a) => a.ayahNumber), [253, 254, 255, 256]);
    expect(state.ayahs.map((a) => a.pageNumber).toSet(), {42});
    expect(state.ayahs.map((a) => a.paraNumber).toSet(), {3});
    expect(state.ayahs[2].textArabic, arabic['2:255']);
    expect(state.ayahs[2].ayahIndex, 262);
    expect(state.surah?.totalAyah, 286);
    expect(state.bismillahPre, isTrue);
    expect(state.loading, isFalse);
    expect(state.error, isFalse);
    expect(state.translationsFailed, isTrue);
    expect(state.offline, isTrue);
    expect(offline.requests, isNotEmpty, reason: 'translations were tried');

    // Surah info falls back to the bundle as well.
    final content = _service(_offline(), bundle: bundle);
    expect((await content.loadSurah(9)).totalAyah, 129);
    expect(await content.loadSurahs(), hasLength(114));
  });

  test('a cached surah reads offline with its translations', () async {
    final online = _service(Adapter(_serve));
    await online.loadAyahs(1, from: 1, to: 7);
    await online.cacheSurah(1, const [161]);

    final offline = _offline();
    final reader = QuranReadingCubit(surahNo: 1, service: _service(offline));
    addTearDown(reader.close);
    await reader.load();

    final state = reader.state;
    final arabic = await QuranBundle().surah(1);
    expect(state.ayahs.map((a) => a.ayahNumber), [1, 2, 3, 4, 5, 6, 7]);
    expect(state.ayahs.map((a) => a.textArabic), arabic.values);
    expect(state.ayahs.map((a) => a.translations[161]?.text), [
      for (var n = 1; n <= 7; n++) 'T 1:$n',
    ]);
    expect(state.translationsFailed, isFalse);
    expect(state.translationsPending, isFalse);
    // The stored surah's metadata, not the bundled snapshot.
    expect(state.surah?.name, 'Server 1');
    expect(offline.requests, isEmpty);
  });

  test('online, the Arabic shows before slow translations arrive', () async {
    final release = Completer<void>();
    final server = Adapter((request) async {
      await release.future;
      return _serve(request);
    });
    final reader = QuranReadingCubit(surahNo: 2, service: _service(server));
    addTearDown(reader.close);
    final states = <QuranReadingState>[];
    final sub = reader.stream.listen(states.add);
    addTearDown(sub.cancel);

    final loading = reader.load(from: 255);
    final shown = await reader.stream.firstWhere((s) => s.translationsPending);
    expect(shown.loading, isFalse);
    expect(shown.ayahs.map((a) => a.ayahNumber), [253, 254, 255, 256]);
    expect(shown.ayahs.every((a) => a.translations.isEmpty), isTrue);
    expect(shown.ayahs.any((a) => a.textArabic == _serverArabic), isFalse);

    release.complete();
    await loading;
    final state = reader.state;
    expect(state.translationsPending, isFalse);
    expect(state.translationsFailed, isFalse);
    expect(state.ayahs.map((a) => a.translations[161]?.text), [
      'T 2:253',
      'T 2:254',
      'T 2:255',
      'T 2:256',
    ]);
    expect(state.ayahs.any((a) => a.textArabic == _serverArabic), isFalse);
    final request = server.requests.firstWhere(
      (r) => r.path == '/quran/surahs/2/ayahs',
    );
    expect(request.queryParameters['from'], 253);
    expect(request.queryParameters['to'], 256);
    await Future<void>.delayed(Duration.zero);
    // Arabic first, then the same page with translations: nothing else.
    expect(states.map((s) => (s.loading, s.translationsPending)), [
      (true, false),
      (false, true),
      (false, false),
    ]);
    // Turning pages needs no network.
    final offline = QuranReadingCubit(
      surahNo: 2,
      service: _service(_offline(), persistCache: false),
    );
    addTearDown(offline.close);
    await offline.load(from: 255);
    await offline.next();
    expect(offline.state.ayahs.first.ayahNumber, 257);
    expect(offline.state.pageNumber, 43);
  });

  test(
    'a bundle missing an ayah is rejected; the reader uses the server',
    () async {
      final broken = QuranBundle(
        bundle: _EditedAssets((arabic) => (arabic['2'] as List).removeLast()),
      );
      await expectLater(broken.surah(1), throwsFormatException);

      final reader = QuranReadingCubit(
        surahNo: 1,
        service: _service(Adapter(_serve), bundle: broken, persistCache: false),
      );
      addTearDown(reader.close);
      await reader.load();
      expect(reader.state.error, isFalse);
      expect(reader.state.ayahs, hasLength(7));
      // Without a bundle there is only the server's text.
      expect(reader.state.ayahs.first.textArabic, _serverArabic);
    },
  );

  test('a failed first read of the bundle is retried', () async {
    final flaky = QuranBundle(bundle: _EditedAssets((_) {}, failures: 1));
    await expectLater(flaky.surah(1), throwsA(isA<FlutterError>()));
    expect(await flaky.surah(1), hasLength(7));
  });

  testWidgets('the reader shows a never-opened surah offline', (tester) async {
    SharedPreferences.setMockInitialValues({
      'quran_show_translation': true,
      'quran_translation_lang': 'bangla',
    });
    final bundle = QuranBundle();
    // Asset reads are real I/O, which the test clock does not run.
    final arabic = (await tester.runAsync(() => bundle.surah(2)))!;
    quranAudioHandler = TestAudio();
    final downloader = TestDownloader();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
          ),
          BlocProvider(create: (_) => ReciterBloc()),
          BlocProvider(
            create: (_) => SurahPlaybackBloc(
              audio: quranAudioHandler,
              downloader: downloader,
            ),
          ),
          BlocProvider(
            create: (_) => SurahAudioDownloadBloc(downloader: downloader),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            home: QuranReadingScreen(
              args: const SurahRouteArgs(
                surahNo: 2,
                surahName: 'Al-Baqarah',
                ayahNo: 255,
              ),
              contentService: _service(
                _offline(),
                bundle: bundle,
                persistCache: false,
              ),
            ),
          ),
        ),
      ),
    );
    // Translation settings read SQLite, also real I/O: give it real time
    // until the page is up (or the expectations below fail).
    final verse = arabic['2:255']!;
    final shown = find.byKey(const ValueKey('quran-translation-retry'));
    for (var i = 0; i < 100 && shown.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(
      find.textContaining(verse.substring(0, 12), findRichText: true),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('quran-translation-retry')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('quran-offline-message')), findsNothing);
  });
}
