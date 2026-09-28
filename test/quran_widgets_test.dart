import 'package:islami_app_noorify/features/quran/presentation/bloc/quran_reading_cubit.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/quran_translation/quran_translation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_audio_downloader.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_audio_handler.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_design.dart';
import 'package:islami_app_noorify/features/quran/presentation/screens/quran_reading_screen.dart';
import 'package:islami_app_noorify/features/quran/presentation/quran_route_args.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/reciter/reciter_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_playback/surah_playback_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_audio_download/surah_audio_download_bloc.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';
import 'quran_content_test.dart' show Adapter, service, ok, page, ayah, surah;
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
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Quran navigation fits a 320px screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => LanguageBloc(),
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const Scaffold(bottomNavigationBar: QuranBottomNav()),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'reader opens saved ayah and renders long translation without overflow',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'quran_arabic_font_family': 'noorehuda',
        'quran_show_translation': true,
        'quran_selected_translation_edition': 'bengali',
        'quran_translation_lang': 'bangla',
      });
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final audio = TestAudio();
      quranAudioHandler = audio;
      final downloader = _Downloader();
      SurahRouteArgs? navigated;
      final adapter = Adapter((r) {
        if (r.path.endsWith('/surahs')) {
          return ok([
            surah,
            {...surah, 'number': 3, 'nameEnglish': 'Aal Imran'},
          ]);
        }
        if (r.path.endsWith('/paras')) {
          return ok([
            {
              'number': 3,
              'nameBangla': 'পারা ৩',
              'ayahCount': 126,
              'start': {'surah': 2, 'ayah': 253},
              'end': {'surah': 3, 'ayah': 92},
              'surahs': [
                {
                  'number': 2,
                  'nameEnglish': 'Al-Baqarah',
                  'nameBangla': 'আল-বাকারা',
                },
              ],
            },
          ]);
        }
        if (r.path.endsWith('/translations')) {
          return ok([
            {
              'resourceId': 161,
              'name': 'Taisirul Quran',
              'authorName': 'Tawheed Publication',
            },
          ]);
        }
        if (!r.path.endsWith('/ayahs')) return ok(surah);
        final verse = ayah(255);
        verse['translations'] = [
          {
            'resourceId': int.parse(
              r.queryParameters['translations'] as String,
            ),
            'name': 'Taisirul Quran',
            'authorName': 'Tawheed Publication',
            'textPlain': List.filled(40, 'আল্লাহ মু’মিনদের অভিভাবক।').join(' '),
          },
        ];
        return page([
          for (
            var n = r.queryParameters['from'] as int;
            n <= (r.queryParameters['to'] as int);
            n++
          )
            {
              ...(n == 255 ? verse : ayah(n)),
              'pageNumber': n < 253
                  ? 41
                  : n <= 256
                  ? 42
                  : 43,
            },
        ]);
      });
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => LanguageBloc()),
            BlocProvider(create: (_) => ReciterBloc()),
            BlocProvider(
              create: (_) =>
                  SurahPlaybackBloc(audio: audio, downloader: downloader),
            ),
            BlocProvider(
              create: (_) => SurahAudioDownloadBloc(downloader: downloader),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, child) => MaterialApp(
              onGenerateRoute: (settings) {
                navigated = settings.arguments as SurahRouteArgs;
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => const Scaffold(body: Text('Next reader')),
                );
              },
              home: QuranReadingScreen(
                args: const SurahRouteArgs(
                  surahNo: 2,
                  surahName: 'Al-Baqarah',
                  ayahNo: 255,
                ),
                contentService: service(adapter),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        adapter.requests
            .where((r) => r.path.endsWith('/ayahs'))
            .first
            .queryParameters['from'],
        241,
      );
      expect(find.textContaining('আল্লাহ মু’মিনদের অভিভাবক।'), findsOneWidget);
      expect(find.text('Page 42 ⌄'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final preferences = tester
          .element(find.text('Page 42 ⌄'))
          .read<QuranTranslationBloc>();
      preferences.add(const SelectTranslationEdition('qc162'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(adapter.requests.last.queryParameters['translations'], '162');
      expect(find.text('Page 42 ⌄'), findsOneWidget);
      preferences.add(const SetShowTranslation(false));
      preferences.add(const SetArabicFontScale(2.5));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Quran actions'));
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Translate'), findsOneWidget);
      await tester.tap(find.text('View in ayat'));
      await tester.pumpAndSettle();
      expect(preferences.state.showTranslation, isTrue);
      await tester.tap(find.byTooltip('Filter Quran'));
      await tester.pumpAndSettle();
      expect(find.text('Filter Quran'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      // Reach the last real page and use the catalog-backed progression card.
      final cubit = tester
          .element(find.text('Page 42 ⌄'))
          .read<QuranReadingCubit>();
      cubit.load(from: 286);
      await tester.pumpAndSettle();
      expect(find.text('Next Surah'), findsOneWidget);
      expect(find.text('Aal Imran'), findsOneWidget);
      await tester.ensureVisible(find.text('Aal Imran'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aal Imran'));
      await tester.pumpAndSettle();
      expect(navigated?.surahNo, 3);
      expect(navigated?.ayahNo, 1);
      expect(find.text('Next reader'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await audio.completed.close();
    },
  );
}
