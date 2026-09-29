import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/shared/widgets/coming_soon_screen.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_design.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/screens/quran_dashboard_screen.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/screens/quran_plan_screen.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/screens/quran_saved_screen.dart';
import 'dart:async';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_download_sheet.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/offline_quran/offline_quran_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_offline_database.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_offline_downloader.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_ayah.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_reader_service.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/quran_route_args.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_filter_sheet.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_modal.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_share.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_ayah_details_sheet.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/screens/quran_tafsir_screen.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/ayah_audio/ayah_audio_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/ayah_bookmark/ayah_bookmark_bloc.dart';
import 'quran_content_test.dart' show Adapter, service, ok, surah, ayah;
import 'quran_playback_test.dart' show TestAudio;

class _DownloadDatabase extends Fake implements QuranOfflineDatabase {
  bool ready = false;
  @override
  Future<bool> isReady() async => ready;
}

class _DownloadSource extends Fake implements QuranOfflineDownloader {
  final progress = StreamController<QuranSetupProgress>();
  @override
  Stream<QuranSetupProgress> downloadAllText() => progress.stream;
}

final previewKey = GlobalKey();
final paras = [
  for (final n in [1, 2])
    {
      'number': n,
      'nameBangla': 'পারা $n',
      'ayahCount': n == 1 ? 141 : 111,
      'start': {'surah': 2, 'ayah': n == 1 ? 1 : 142},
      'end': {'surah': 2, 'ayah': n == 1 ? 141 : 252},
      'surahs': [
        {'number': 2, 'nameEnglish': 'Al-Baqarah', 'nameBangla': 'আল-বাকারা'},
      ],
    },
];
Future<void> preview(WidgetTester tester, String name) async {
  const folder = String.fromEnvironment('QURAN_DESIGN_PREVIEWS');
  if (folder.isEmpty) return;
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pump();
  final boundary =
      previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(folder).create(recursive: true);
    await File('$folder/$name.png').writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

/// The app's language, provided at its root, defaults to Bangla; these tests
/// assert English text.
Widget _english(Widget child) => BlocProvider(
  create: (_) =>
      LanguageBloc(initialLanguage: AppLanguage.english, persist: (_) async {}),
  child: child,
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const fonts = String.fromEnvironment('QURAN_PREVIEW_FONTS');
    if (fonts.isNotEmpty) {
      for (final font in [
        ('Roboto', 'Roboto-Regular.ttf'),
        ('MaterialIcons', 'MaterialIcons-Regular.otf'),
      ]) {
        final loader = FontLoader(font.$1)
          ..addFont(
            File(
              '$fonts/${font.$2}',
            ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          );
        await loader.load();
      }
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('Quran bar switches sections in place and preserves its route', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    Widget home(BuildContext context) => Scaffold(
      body: TextButton(
        onPressed: () => Navigator.pushNamed(context, RouteNames.quran),
        child: const Text('Open Quran'),
      ),
    );
    await tester.pumpWidget(
      BlocProvider(
        // The app defaults to Bangla; this test reads English labels.
        create: (_) =>
            LanguageBloc()..add(const UpdateLanguage(AppLanguage.english)),
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            navigatorKey: navigator,
            onGenerateInitialRoutes: (_) => [
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: RouteNames.home),
                builder: home,
              ),
            ],
            routes: {
              RouteNames.home: home,
              RouteNames.quran: (_) =>
                  const QuranTabShell(child: Scaffold(body: TextField())),
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Quran'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    expect(navigator.currentState!.canPop(), isTrue);
    await tester.enterText(find.byType(TextField), 'Saved search');
    final originalContent = tester.element(find.byType(TextField));
    final originalBar = tester.element(find.byType(QuranBottomNav));
    final originalRoute = ModalRoute.of(originalBar);
    final barPosition = tester.getRect(find.byType(QuranBottomNav));
    for (final (section, screen) in [
      ('learn', ComingSoonScreen),
      ('saved', QuranSavedScreen),
      ('plan', QuranPlanScreen),
      ('dashboard', QuranDashboardScreen),
    ]) {
      final tab = find.byKey(ValueKey('quran-nav-$section'));
      await tester.tap(tab);
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget);
      expect(tester.element(find.byType(QuranBottomNav)), same(originalBar));
      expect(ModalRoute.of(tester.element(tab)), same(originalRoute));
      expect(tester.getRect(find.byType(QuranBottomNav)), barPosition);
      expect(
        tester.widget<QuranBottomNav>(find.byType(QuranBottomNav)).selected,
        section,
      );
      expect(tester.takeException(), isNull);
    }
    await navigator.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(QuranDashboardScreen), findsNothing);
    expect(tester.element(find.byType(TextField)), same(originalContent));
    expect(find.text('Saved search'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('quran-nav-learn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quran-nav-home')));
    await tester.pumpAndSettle();
    expect(tester.element(find.byType(TextField)), same(originalContent));
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Open Quran'), findsOneWidget);
    expect(navigator.currentState!.canPop(), isFalse);
  });
  testWidgets(
    'download uses existing progress and reports Tajweed availability honestly',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = _DownloadDatabase();
      final source = _DownloadSource();
      final bloc = OfflineQuranBloc(database: db, downloader: source);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        _english(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Roboto'),
            builder: (_, child) =>
                RepaintBoundary(key: previewKey, child: child!),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showQuranDownload(context, bloc: bloc),
                  child: const Text('Open download'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open download'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Tajweed edition is not available'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Download Quran'));
      await tester.tap(find.text('Download Quran'));
      await tester.pump();
      source.progress.add(
        const QuranSetupProgress(QuranSetupPhase.building, 61, 100),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('61%'), findsOneWidget);
      await preview(tester, 'download');
      db.ready = true;
      await source.progress.close();
      await tester.pumpAndSettle();
      expect(find.text('Quran ready for offline reading'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Open download'), findsOneWidget);
    },
  );
  testWidgets(
    'filter searches real catalog, selects Para boundaries and applies ayah',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = service(
        Adapter((r) => r.path.endsWith('/paras') ? ok(paras) : ok([surah])),
      );
      SurahRouteArgs? result;
      await tester.pumpWidget(
        _english(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Roboto'),
            builder: (context, child) =>
                RepaintBoundary(key: previewKey, child: child!),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    result = await showQuranModal<SurahRouteArgs>(
                      context,
                      QuranFilterSheet(
                        service: api,
                        initial: const SurahRouteArgs(
                          surahNo: 2,
                          surahName: 'Al-Baqarah',
                          ayahNo: 5,
                        ),
                      ),
                    );
                  },
                  child: const Text('Filter'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      await preview(tester, 'filter');
      // Search opens in a popup from the search icon.
      await tester.tap(find.byKey(const ValueKey('quran-filter-search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pumpAndSettle();
      expect(find.text('No Surahs found'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Baqarah');
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Al-Baqarah'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      await tester.drag(find.byType(PageView), const Offset(-250, 0));
      await tester.pumpAndSettle();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(QuranAyahWheel));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(QuranAyahWheel), const Offset(-110, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(result?.surahNo, 2);
      expect(result?.paraNumber, 2);
      expect(result?.paraStartAyah, 142);
      expect(result?.endAyah, 252);
      expect(result!.ayahNo, inInclusiveRange(142, 252));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('ayah wheel haptics only follow changed selections', (
    tester,
  ) async {
    final changed = <int>[];
    var haptics = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      _english(
        MaterialApp(
          home: Scaffold(
            body: QuranAyahWheel(
              first: 1,
              last: 30,
              initial: 1,
              onChanged: changed.add,
            ),
          ),
        ),
      ),
    );
    expect(haptics, 0);
    await tester.drag(find.byType(QuranAyahWheel), const Offset(-180, 0));
    await tester.pumpAndSettle();
    expect(changed, isNotEmpty);
    expect(haptics, changed.length);
    for (var i = 1; i < changed.length; i++) {
      expect(changed[i], isNot(changed[i - 1]));
    }
    final count = haptics;
    await tester.pump(const Duration(seconds: 2));
    expect(haptics, count);
  });
  testWidgets(
    'copy and native share preserve Arabic, translation and verse reference',
    (tester) async {
      final verse = QuranAyah.fromJson(ayah(255));
      String? copied;
      MethodCall? shared;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      const channel = MethodChannel('dev.fluttercommunity.plus/share');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        shared = call;
        return 'success';
      });
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      });
      await tester.pumpWidget(
        _english(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    TextButton(
                      onPressed: () => shareQuranAyah(
                        context,
                        verse,
                        translation: 161,
                        copy: true,
                      ),
                      child: const Text('Copy'),
                    ),
                    TextButton(
                      onPressed: () =>
                          shareQuranAyah(context, verse, translation: 161),
                      child: const Text('Share'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(copied, contains(verse.textArabic));
      expect(copied, contains('Quran 2:255'));
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(shared?.method, 'share');
      expect((shared!.arguments as Map)['text'], copied);
    },
  );
  testWidgets('ayah drawer switches actual resources without changing verse', (
    tester,
  ) async {
    final audio = TestAudio();
    final adapter = Adapter(
      (r) => r.path.endsWith('/translations')
          ? ok([
              {'resourceId': 161, 'name': 'Taisirul Quran'},
              {'resourceId': 20, 'name': 'Saheeh International'},
            ])
          : ok(ayah(255)),
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
          ),
          BlocProvider(create: (_) => AyahAudioBloc(audio: audio)),
          BlocProvider(
            create: (_) => AyahBookmarkBloc(
              surahNo: 2,
              ayahNo: 255,
              surahName: 'Al-Baqarah',
              snippet: '',
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: QuranAyahDetails(
              surah: 2,
              ayah: 255,
              translation: 161,
              totalAyah: 286,
              service: service(adapter),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('এসব আল্লাহরই আয়াত'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(adapter.requests.last.path, '/quran/ayahs/2/255');
    expect(adapter.requests.last.queryParameters['translations'], 20);
    expect(find.text('English'), findsNWidgets(2));
    await tester.tap(find.text('Bangla'));
    await tester.pumpAndSettle();
    expect(find.text('এসব আল্লাহরই আয়াত'), findsOneWidget);
    expect(adapter.requests.where((r) => r.path.contains('/ayahs/')).length, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await audio.completed.close();
  });
  testWidgets(
    'Tafsir uses existing service, correct verse and selected language',
    (tester) async {
      final requests = <Uri>[];
      final client = MockClient((r) async {
        requests.add(r.url);
        return http.Response(
          jsonEncode({
            'tafsir': {'text': '<p>Explanation ${r.url.path}</p>'},
          }),
          200,
        );
      });
      await tester.pumpWidget(
        _english(
          MaterialApp(
            home: QuranTafsirScreen(
              verseKey: '2:255',
              isBangla: true,
              ayahs: [QuranAyah.fromJson(ayah(255))],
              readerService: QuranComReaderService(client: client),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests.single.path, contains('/165/by_ayah/2:255'));
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(requests.last.path, contains('/169/by_ayah/2:255'));
      expect(find.textContaining('Explanation'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
