import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_page_index.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/last_read/last_read_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/offline_quran/offline_quran_bloc.dart';
import 'package:islami_app_noorify/features/quran/presentation/quran_route_args.dart';
import 'package:islami_app_noorify/features/quran/presentation/quran_text.dart';
import 'package:islami_app_noorify/features/quran/presentation/screens/surah_list_screen.dart';
import 'package:islami_app_noorify/features/quran/presentation/screens/create_quran_plan_screen.dart';
import 'package:islami_app_noorify/features/quran/presentation/screens/quran_dashboard_screen.dart';
import 'package:islami_app_noorify/features/quran/presentation/screens/quran_plan_screen.dart';
import 'package:islami_app_noorify/features/quran/presentation/screens/quran_saved_screen.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_design.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

LanguageBloc _language(AppLanguage language) =>
    LanguageBloc()..add(UpdateLanguage(language));

/// Small, typical and large phones (logical pixels).
const _phones = [Size(320, 568), Size(390, 844), Size(430, 932)];

Future<void> _pumpAt(
  WidgetTester tester,
  Size size,
  AppLanguage language,
  Widget child, {
  RouteFactory? onGenerateRoute,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    BlocProvider<LanguageBloc>(
      create: (_) => _language(language),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) =>
            MaterialApp(home: child, onGenerateRoute: onGenerateRoute),
      ),
    ),
  );
  // Fixed pumps: some screens show endlessly animating loading placeholders.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

List<QuranPageStart> _bundledPages() => [
  for (final e
      in (jsonDecode(
                File('assets/database/quran_pages.json').readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>())
    QuranPageStart(
      page: e['page'] as int,
      surahNo: e['surah'] as int,
      ayahNo: e['ayah'] as int,
      paraNo: e['para'] as int,
    ),
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Bangla text uses Bengali digits, names and places', () {
    expect(QuranText.english.paraTitle(1), 'Para 1');
    const t = QuranText.bangla;
    expect(t.paraTitle(12), 'পারা ১২');
    expect(t.pageTitle(604), 'পৃষ্ঠা ৬০৪');
    expect(t.surahName(1, 'Al-Fatiha'), 'আল-ফাতিহা');
    expect(t.surahName(114, 'An-Nas'), 'আন-নাস');
    expect(t.revelationPlace('meccan'), 'মাক্কী');
    expect(t.revelationPlace('madinah'), 'মাদানী');
    expect(t.duration(const Duration(hours: 2, minutes: 5)), '২ ঘণ্টা ৫ মিনিট');
    expect(QuranText.english.surahName(1, 'Al-Fatiha'), 'Al-Fatiha');
  });

  test('page index covers all 604 Mushaf pages in order', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final pages = await QuranPageIndex.load(bundle: rootBundle);
    expect(pages, hasLength(604));
    expect([for (final p in pages) p.page], [for (var i = 1; i <= 604; i++) i]);
    expect([pages.first.surahNo, pages.first.ayahNo], [1, 1]);
    expect([pages[49].surahNo, pages[49].ayahNo], [3, 1]);
    expect(pages.last.surahNo, 112);
  });

  for (final language in AppLanguage.values) {
    for (final size in _phones) {
      final label =
          '${language.name} ${size.width.toInt()}x'
          '${size.height.toInt()}';

      testWidgets('Saved fits a $label phone', (tester) async {
        await _pumpAt(tester, size, language, const QuranSavedScreen());
        expect(
          find.text(
            language == AppLanguage.bangla ? 'প্লে লিস্ট' : 'Play List',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('Planner fits a $label phone', (tester) async {
        await _pumpAt(tester, size, language, const QuranPlanScreen());
        await tester.tap(
          find.text(
            language == AppLanguage.bangla ? 'পরিকল্পনা খুঁজুন' : 'Search Plan',
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            language == AppLanguage.bangla
                ? 'এক মাসে কুরআন'
                : 'One month Quran',
          ),
          findsOneWidget,
        );
        expect(
          find.text(language == AppLanguage.bangla ? '৩০ দিন' : '30 Days'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('Create plan fits a $label phone', (tester) async {
        await _pumpAt(tester, size, language, const CreateQuranPlanScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('Dashboard fits a $label phone', (tester) async {
        await _pumpAt(tester, size, language, const QuranDashboardScreen());
        expect(
          find.text(
            language == AppLanguage.bangla
                ? 'মোট কুরআন পাঠের সময়'
                : 'Total Quran Reading time',
          ),
          findsOneWidget,
        );
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -600),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('Home and its Page tab fit a $label phone', (tester) async {
        SurahRouteArgs? opened;
        // Asset loading is real I/O, so hand the screen the bundled index
        // read straight from disk.
        QuranPageIndex.debugSeed(_bundledPages());
        await _pumpAt(
          tester,
          size,
          language,
          MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => LastReadBloc()),
              BlocProvider(create: (_) => OfflineQuranBloc()),
            ],
            child: const SurahListScreen(),
          ),
          onGenerateRoute: (settings) {
            opened = settings.arguments as SurahRouteArgs?;
            return MaterialPageRoute<void>(builder: (_) => const Scaffold());
          },
        );
        // Loading placeholders animate forever, so pump a fixed time.
        Future<void> settle() async {
          for (var i = 0; i < 5; i++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
        }

        await tester.tap(find.byKey(const ValueKey('quran-home-tab-2')));
        await settle();
        final bangla = language == AppLanguage.bangla;
        expect(find.text(bangla ? 'পৃষ্ঠা ১' : 'Page 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Tapping a page opens the reader at that page's first ayah.
        await tester.tap(find.byKey(const ValueKey('quran-page-1')));
        await settle();
        expect([opened?.surahNo, opened?.ayahNo], [1, 1]);
      });

      testWidgets('Surah rows fit a $label phone', (tester) async {
        await _pumpAt(
          tester,
          size,
          language,
          Scaffold(
            body: ListView(
              children: [
                for (final n in [1, 2, 114])
                  QuranListRow(
                    number: n,
                    title: 'A long Surah name that keeps going on',
                    subtitle: 'Meccan · 286 Ayahs · and more detail',
                    arabic: 'الفاتحة',
                    onTap: () {},
                  ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
