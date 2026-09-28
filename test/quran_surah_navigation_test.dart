import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/constants/app_routes.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_audio_handler.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_audio_downloader.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/reciter/reciter_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_audio_download/surah_audio_download_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_playback/surah_playback_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/quran_route_args.dart';
import 'package:islami_app_noorify/features/quran/presentation/screens/quran_reading_screen.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_page_viewport.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';
import 'quran_content_test.dart' show Adapter, ok, service;
import 'quran_playback_test.dart' show TestAudio, TestDownloader;

class _Downloader extends TestDownloader {
  @override
  Future<AudioDownloadProgress> surahStatus({
    required int reciterId,
    required int surahNo,
    required int totalAyah,
  }) async => AudioDownloadProgress(totalAyah, totalAyah);
}

void main() {
  testWidgets('Surah route animation follows the swipe direction', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('anchor'))),
    );
    final context = tester.element(find.text('anchor'));
    for (final (forward, expectedDx) in [(true, 1.0), (false, -1.0)]) {
      final route = AppRoutes.onGenerateRoute(
        RouteSettings(
          name: RouteNames.quranSurahDetail,
          arguments: SurahRouteArgs(
            surahNo: forward ? 3 : 2,
            surahName: '',
            swipeForward: forward,
          ),
        ),
      );
      expect(route, isA<PageRouteBuilder>());
      final transition = (route as PageRouteBuilder).transitionsBuilder(
        context,
        const AlwaysStoppedAnimation<double>(0),
        const AlwaysStoppedAnimation<double>(0),
        const SizedBox(),
      );
      expect((transition as SlideTransition).position.value.dx, expectedDx);
    }
  });

  testWidgets('boundary swipes visit adjacent Surahs and keep elapsed time', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'quran_show_translation': false,
      'quran_selected_translation_edition': 'bengali',
    });
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final audio = TestAudio();
    quranAudioHandler = audio;
    addTearDown(audio.completed.close);
    final downloader = _Downloader();
    final adapter = Adapter((RequestOptions request) {
      if (request.path.endsWith('/translations')) {
        return ok([
          {
            'resourceId': 161,
            'name': 'Taisirul Quran',
            'authorName': 'Tawheed Publication',
          },
        ]);
      }
      final segments = request.path.split('/');
      final number = int.parse(segments[segments.indexOf('surahs') + 1]);
      final count = number == 2 ? 3 : 2;
      final surah = {
        'number': number,
        'nameEnglish': 'Surah $number',
        'nameArabic': 'سورة',
        'nameBangla': 'সুরা',
        'ayahCount': count,
        'revelationType': 'meccan',
      };
      if (!request.path.endsWith('/ayahs')) return ok(surah);
      final from = request.queryParameters['from'] as int;
      final to = request.queryParameters['to'] as int;
      return ok(
        {
          'surah': {
            ...surah,
            'surahNumber': number,
            'bismillahPre': true,
            'pages': [number],
          },
          'ayahs': [
            for (var ayah = from; ayah <= to; ayah++)
              {
                'surahNumber': number,
                'ayahNumber': ayah,
                'verseKey': '$number:$ayah',
                'ayahIndex': ayah,
                'paraNumber': 1,
                'pageNumber': number,
                'textArabic': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                'translations': [
                  {
                    'resourceId': 161,
                    'name': 'Taisirul Quran',
                    'authorName': 'Tawheed Publication',
                    'textPlain': 'আল্লাহ',
                  },
                ],
              },
          ],
        },
        meta: {
          'page': 1,
          'limit': to - from + 1,
          'total': count,
          'totalPage': 1,
        },
      );
    });
    final content = service(adapter);
    final navigator = GlobalKey<NavigatorState>();
    final session = QuranReadingSession(
      initialElapsed: const Duration(minutes: 2, seconds: 5),
    );
    Widget reader(SurahRouteArgs args) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ReciterBloc()),
        BlocProvider(
          create: (_) =>
              SurahPlaybackBloc(audio: audio, downloader: downloader),
        ),
        BlocProvider(
          create: (_) => SurahAudioDownloadBloc(downloader: downloader),
        ),
      ],
      child: QuranReadingScreen(args: args, contentService: content),
    );
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => LanguageBloc(),
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            navigatorKey: navigator,
            home: reader(
              SurahRouteArgs(
                surahNo: 2,
                surahName: 'Surah 2',
                readingSession: session,
              ),
            ),
            onGenerateRoute: (settings) =>
                settings.name == RouteNames.quranSurahDetail
                ? MaterialPageRoute<void>(
                    settings: settings,
                    builder: (_) =>
                        reader(settings.arguments! as SurahRouteArgs),
                  )
                : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Page 2 ⌄'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(session.elapsedSeconds, greaterThanOrEqualTo(125));
    final before = session.elapsedSeconds;
    final timer = find.byKey(const ValueKey('quran-reading-timer'));
    int displayedSeconds() {
      final text = tester.widget<Text>(timer).data ?? '';
      final match = RegExp(r'(\d+) min (\d+) sec').firstMatch(text);
      expect(match, isNotNull);
      return int.parse(match!.group(1)!) * 60 + int.parse(match.group(2)!);
    }

    final shownBefore = displayedSeconds();
    expect(shownBefore, greaterThanOrEqualTo(125));

    await tester.drag(
      find.byKey(const ValueKey('quran-frame-interior')),
      const Offset(-180, 0),
    );
    await tester.pumpAndSettle();
    final nextRoute = ModalRoute.of(
      tester.element(find.byType(QuranPageViewport)),
    )!;
    final nextArgs = nextRoute.settings.arguments! as SurahRouteArgs;
    expect([nextArgs.surahNo, nextArgs.ayahNo], [3, 1]);
    expect(nextArgs.readingSession, same(session));
    expect(find.text('Page 3 ⌄'), findsOneWidget);
    expect(session.elapsedSeconds, greaterThanOrEqualTo(before));
    expect(displayedSeconds(), greaterThanOrEqualTo(shownBefore));

    await tester.drag(
      find.byKey(const ValueKey('quran-frame-interior')),
      const Offset(180, 0),
    );
    await tester.pumpAndSettle();
    final previousRoute = ModalRoute.of(
      tester.element(find.byType(QuranPageViewport)),
    )!;
    final previousArgs = previousRoute.settings.arguments! as SurahRouteArgs;
    expect([previousArgs.surahNo, previousArgs.ayahNo], [2, 3]);
    expect(previousArgs.readingSession, same(session));
    expect(find.text('Page 2 ⌄'), findsOneWidget);
    expect(session.elapsedSeconds, greaterThanOrEqualTo(before));
    expect(displayedSeconds(), greaterThanOrEqualTo(shownBefore));
    expect(
      adapter.requests
          .where((request) => request.path.endsWith('/surahs/3'))
          .length,
      1,
    );
    expect(tester.takeException(), isNull);
  });
}
