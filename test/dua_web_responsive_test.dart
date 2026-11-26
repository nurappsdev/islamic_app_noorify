import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuhfatul_muslim/core/widgets/app_bottom_nav_bar.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/data/dua_catalog.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_all_category_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_all_dua_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_group_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_intro_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_dashboard_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_featured_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_category_tile.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_featured_card.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_responsive.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Deliberately long names and titles: a layout that survives these
/// survives the real ones.
Map<String, dynamic> _category(int i) => {
  '_id': 'category-$i',
  'slug': 'category-$i',
  'name': {
    'en': 'Protection & Ruqyah Duas For The Morning $i',
    'bn': 'সকালে উপনীত হওয়ার দোয়া $i',
  },
  'description': {'en': 'Duas for protection $i', 'bn': 'বর্ণনা $i'},
  'totalDuasCount': 12 + i,
  'displayOrder': i,
};

Map<String, dynamic> _featured(int i) => {
  '_id': 'dua-$i',
  'categoryId': 'category-$i',
  'title': {
    'en': 'Falaq, Nas & Ayat al-Kursi Protection Dua $i',
    'bn': 'আয়াতুল কুরসি $i',
  },
  'arabic': 'سُبْحَانَ اللهِ',
  'transliteration': {'en': 'Subhanallah', 'bn': 'সুবহানাল্লাহ'},
  'translation': {'en': 'Glory be to Allah', 'bn': 'আল্লাহ পবিত্র'},
};

class _Repo extends Fake implements DuaRepository {
  _Repo({this.count = 9});

  final int count;

  @override
  Future<List<DuaCategoryModel>> getCategories() async => [
    for (var i = 0; i < count; i++) DuaCategoryModel.fromJson(_category(i)),
  ];

  @override
  Future<List<DuaFeaturedModel>> getFeatured() async => [
    for (var i = 0; i < count; i++) DuaFeaturedModel.fromJson(_featured(i)),
  ];
}

/// Every width the browser has to survive, matching
/// `dua_dashboard_responsive_test.dart`: a small phone, the design size, a
/// large phone, the 600-wide column `WebMobileCanvas` used to cap the
/// browser at, a tablet, and two desktop windows.
const _webWidths = <double>[320, 360, 375, 430, 600, 900, 1280, 1600];

/// What a phone or tablet can actually be. ScreenUtil's scaling is off on
/// the browser (`enableScaleWH: () => !kIsWeb` in `main_app.dart`), so these
/// units only ever run on Android and iOS.
const _deviceWidths = <double>[320, 360, 375, 430, 600, 900];

void main() {
  /// Lays [screen] out at [width].
  ///
  /// [webUnits] mirrors `main_app.dart`'s `enableScaleWH: () => !kIsWeb`: on
  /// the browser ScreenUtil stops scaling, so `.w`/`.h`/`.sp` become raw
  /// design numbers.
  Future<void> pumpAt(
    WidgetTester tester,
    Widget screen,
    double width, {
    required bool webUnits,
  }) async {
    tester.view.physicalSize = Size(width * 3, (width >= 720 ? 900 : 812) * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        enableScaleWH: () => !webUnits,
        enableScaleText: () => !webUnits,
        builder: (context, child) => BlocProvider(
          create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
          child: MaterialApp(home: screen),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  /// How many tiles sit on the grid's first row.
  int columnsOf(WidgetTester tester, Type tile) {
    final tops = tester
        .widgetList(find.byType(tile))
        .map((w) => tester.getTopLeft(find.byWidget(w)).dy)
        .toList();
    if (tops.isEmpty) return 0;
    final first = tops.reduce((a, b) => a < b ? a : b);
    return tops.where((t) => (t - first).abs() < 1).length;
  }

  final screens = <String, Widget Function()>{
    'dashboard': () => DuaDashboardScreen(repository: _Repo()),
    'all categories': () => DuaAllCategoryScreen(repository: _Repo()),
    'featured': () => DuaFeaturedScreen(repository: _Repo()),
    'intro': () => const DuaIntroScreen(),
    'all dua': () => DuaAllDuaScreen(featured: DuaCatalog.featured.first),
    'group': () => DuaGroupScreen(featured: DuaCatalog.featured.first),
  };

  group('column counts follow the window', () {
    testWidgets('a phone keeps two category columns', (tester) async {
      await pumpAt(
        tester,
        DuaAllCategoryScreen(repository: _Repo()),
        375,
        webUnits: true,
      );
      expect(tester.takeException(), isNull);
      expect(columnsOf(tester, DuaCategoryTile), 2);
    });

    testWidgets('a tablet-width browser gets three', (tester) async {
      await pumpAt(
        tester,
        DuaAllCategoryScreen(repository: _Repo()),
        900,
        webUnits: true,
      );
      expect(tester.takeException(), isNull);
      expect(columnsOf(tester, DuaCategoryTile), 3);
    });

    testWidgets('a desktop browser gets four', (tester) async {
      await pumpAt(
        tester,
        DuaAllCategoryScreen(repository: _Repo()),
        1280,
        webUnits: true,
      );
      expect(tester.takeException(), isNull);
      expect(columnsOf(tester, DuaCategoryTile), 4);
    });

    testWidgets('featured cards pair up on a wide window', (tester) async {
      await pumpAt(
        tester,
        DuaFeaturedScreen(repository: _Repo()),
        1280,
        webUnits: true,
      );
      expect(tester.takeException(), isNull);
      expect(columnsOf(tester, DuaFeaturedCard), 2);
    });

    testWidgets('featured cards stay one per row on a phone', (tester) async {
      await pumpAt(
        tester,
        DuaFeaturedScreen(repository: _Repo()),
        375,
        webUnits: true,
      );
      expect(tester.takeException(), isNull);
      expect(columnsOf(tester, DuaFeaturedCard), 1);
    });
  });

  group('content stops widening', () {
    testWidgets('the grid is centred, not stretched, at 1600px', (
      tester,
    ) async {
      await pumpAt(
        tester,
        DuaAllCategoryScreen(repository: _Repo()),
        1600,
        webUnits: true,
      );
      expect(tester.takeException(), isNull);

      final tile = find.byType(DuaCategoryTile).first;
      final left = tester.getTopLeft(tile).dx;
      final right = tester
          .getBottomRight(find.byType(DuaCategoryTile).at(3))
          .dx;
      // A margin either side rather than edge to edge.
      expect(left, greaterThan(150));
      expect(right - left, lessThanOrEqualTo(DuaLayout.maxContent + 1));
    });

    testWidgets('the nav pill does not span the whole window', (tester) async {
      await pumpAt(
        tester,
        DuaDashboardScreen(repository: _Repo()),
        1600,
        webUnits: true,
      );
      expect(tester.takeException(), isNull);

      // The pill itself, not the Center that fills the window around it.
      final nav = tester.getSize(find.byType(AppBottomNavBar));
      expect(nav.width, lessThanOrEqualTo(DuaLayout.maxNav + 1));
    });
  });

  // The real safety net: no overflow on any width, in either unit mode.
  for (final webUnits in [false, true]) {
    final mode = webUnits ? 'web units (no ScreenUtil scaling)' : 'mobile';
    for (final entry in screens.entries) {
      group('${entry.key} lays out on $mode', () {
        for (final width in webUnits ? _webWidths : _deviceWidths) {
          testWidgets('at ${width.toInt()}px', (tester) async {
            await pumpAt(tester, entry.value(), width, webUnits: webUnits);
            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.key} at ${width}px, webUnits=$webUnits',
            );
          });
        }
      });
    }
  }
}
