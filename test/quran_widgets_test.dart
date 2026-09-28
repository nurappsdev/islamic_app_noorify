import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_reader_service.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_tafsir_content.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_page_viewport.dart';
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
        create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
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
            BlocProvider(create: (_) => LanguageBloc(initialLanguage: AppLanguage.english)),
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
              home: QuranReadingScreen(
                args: const SurahRouteArgs(
                  surahNo: 2,
                  surahName: 'Al-Baqarah',
                  ayahNo: 255,
                ),
                contentService: service(adapter),
                tafsirService: QuranComReaderService(
                  client: MockClient(
                    (r) async => http.Response(
                      jsonEncode({
                        'tafsir': {
                          'text': List.filled(
                            20,
                            'Tafsir for ${r.url.path}',
                          ).join(' '),
                        },
                      }),
                      200,
                    ),
                  ),
                ),
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
      final viewport = find.byType(QuranPageViewport);
      final pageElement = tester.element(viewport);
      final pageHeight = tester.getSize(viewport).height;
      final arabicScroll = tester.widget<SingleChildScrollView>(
        find.descendant(
          of: viewport,
          matching: find.byType(SingleChildScrollView),
        ),
      );
      arabicScroll.controller!.jumpTo(80);
      await tester.pump();
      final oldOffset = arabicScroll.controller!.offset;
      final originalRoute = ModalRoute.of(tester.element(viewport));
      await tester.tap(find.byKey(const ValueKey('quran-toggle-tafsir')));
      await tester.pumpAndSettle();
      expect(find.byType(QuranTafsirContent), findsOneWidget);
      expect(tester.element(viewport), same(pageElement));
      expect(ModalRoute.of(tester.element(viewport)), same(originalRoute));
      expect(tester.getSize(viewport).height, pageHeight);
      expect(arabicScroll.controller!.offset, oldOffset);
      final outer = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('quran-reader-scroll')),
      );
      expect(outer.controller!.position.maxScrollExtent, greaterThan(0));
      outer.controller!.jumpTo(outer.controller!.position.maxScrollExtent);
      await tester.pump();
      await tester.ensureVisible(find.byTooltip('Close tafsir'));
      await tester.tap(find.byTooltip('Close tafsir'));
      await tester.pumpAndSettle();
      expect(find.byType(QuranTafsirContent), findsNothing);
      expect(tester.element(viewport), same(pageElement));
      expect(arabicScroll.controller!.offset, oldOffset);
      expect(outer.controller!.offset, 0);
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
      expect(find.text('Show under each ayah'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('quran-ayat-view-english')));
      await tester.pumpAndSettle();
      expect(preferences.state.showTranslation, isTrue);
      await tester.tap(find.byTooltip('Filter Quran'));
      await tester.pumpAndSettle();
      expect(find.text('Filter Quran'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      // Filtering must return to the same reader and preserve its position.
      final cubit = tester
          .element(find.text('Page 42 ⌄'))
          .read<QuranReadingCubit>();
      expect(cubit.state.pageNumber, 42);
      expect(cubit.state.error, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await audio.completed.close();
    },
  );
}
