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
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_item_tile.dart';
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
          // `DuaWebTypography` is what `AppRoutes` wraps every Dua route in
          // on the browser: the page's type grows with the window there, so
          // the widths below are laid out with the type they really carry.
          child: MaterialApp(
            home: DuaWebTypography(enabled: webUnits, child: screen),
          ),
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

    testWidgets('a full-screen window gets five', (tester) async {
      // The count follows the content column's own width, which a 1600px
      // window fills to `DuaLayout.maxContent`.
      await pumpAt(
        tester,
        DuaAllCategoryScreen(repository: _Repo(count: 12)),
        1600,
        webUnits: true,
      );
      expect(tester.takeException(), isNull);
      expect(columnsOf(tester, DuaCategoryTile), 5);
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

      // The whole first row, however many columns this width fits.
      final tiles = find.byType(DuaCategoryTile);
      final first = tester.getRect(tiles.first);
      var right = first.right;
      for (var i = 0; i < tiles.evaluate().length; i++) {
        final rect = tester.getRect(tiles.at(i));
        if ((rect.top - first.top).abs() < 1 && rect.right > right) {
          right = rect.right;
        }
      }
      // A margin either side rather than edge to edge: the window's width
      // past the cap goes to the margins, and the page keeps its own 16px
      // gutter inside them. Derived from the cap rather than restating it,
      // so raising the cap moves this with it.
      final margin = 16 + (1600 - 32 - DuaLayout.maxContent) / 2;
      expect(first.left, closeTo(margin, 2));
      expect(right - first.left, lessThanOrEqualTo(DuaLayout.maxContent + 1));
    });

    testWidgets('the nav pill stays at the foot of the page', (tester) async {
      // Regression: capping the pill's width with a `Center` also took the
      // full page height and centred the pill vertically, leaving it
      // floating in the middle of the screen.
      await pumpAt(
        tester,
        DuaDashboardScreen(repository: _Repo()),
        1280,
        webUnits: true,
      );
      expect(tester.takeException(), isNull);

      final pill = tester.getRect(find.byType(AppBottomNavBar));
      final page = tester.getSize(find.byType(MaterialApp)).height;
      expect(
        pill.bottom,
        greaterThan(page - 80),
        reason:
            'the pill is at ${pill.top}-${pill.bottom} on a '
            '${page}px page, not at its foot',
      );
      // And it is a bar, not a full-height box.
      expect(pill.height, lessThan(140));
    });

    for (final width in [900.0, 1280.0, 1920.0]) {
      testWidgets(
        'the nav pill lines up with the content at ${width.toInt()}px',
        (tester) async {
          await pumpAt(
            tester,
            DuaDashboardScreen(repository: _Repo()),
            width,
            webUnits: true,
          );
          expect(tester.takeException(), isNull);

          // `AppBottomNavBar` carries a 16px margin inside its own box, so the
          // visible pill is that box inset by 16 either side.
          final navBox = tester.getRect(find.byType(AppBottomNavBar));
          final pillLeft = navBox.left + 16;
          final pillRight = navBox.right - 16;

          // The content column: the first row of category tiles.
          final tiles = find.byType(DuaCategoryTile);
          final first = tester.getRect(tiles.first);
          var contentRight = first.right;
          for (var i = 0; i < tiles.evaluate().length; i++) {
            final r = tester.getRect(tiles.at(i));
            if ((r.top - first.top).abs() < 1 && r.right > contentRight) {
              contentRight = r.right;
            }
          }

          expect(pillLeft, closeTo(first.left, 1));
          expect(pillRight, closeTo(contentRight, 1));
          // And it is still capped, not stretched to the window.
          expect(navBox.width, lessThanOrEqualTo(DuaLayout.maxNav + 1));
        },
      );
    }
  });

  group('every nav page lines its content up with the pill', () {
    /// The pill's visible left/right edge at [width]: its box is capped at
    /// [DuaLayout.maxNav] and it carries a 16px margin inside that.
    (double, double) pillEdges(double width) {
      final box = width > DuaLayout.maxNav ? DuaLayout.maxNav : width;
      final left = (width - box) / 2 + 16;
      return (left, width - left);
    }

    /// The side gutters `duaPagePadding` asks for at [width] - the planner,
    /// the recitation history and plan create are padded with it, and are
    /// too deep in their dependency graphs to build for a measurement.
    Future<EdgeInsets> pagePadding(WidgetTester tester, double width) async {
      late EdgeInsets padding;
      tester.view.physicalSize = Size(width * 3, 900 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 900)),
          child: Builder(
            builder: (context) {
              padding = duaPagePadding(context, left: 16, right: 16);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return padding;
    }

    for (final width in [375.0, 600.0, 900.0, 1280.0, 1440.0, 1600.0, 1920.0]) {
      testWidgets('a self-padding page at ${width.toInt()}px', (tester) async {
        // The Dua group page: an unpadded list whose sections pad
        // themselves, so the column is capped at `maxOuter`.
        await pumpAt(
          tester,
          DuaGroupScreen(featured: DuaCatalog.featured.first),
          width,
          webUnits: true,
        );
        expect(tester.takeException(), isNull);

        final (expectedLeft, expectedRight) = pillEdges(width);
        final navBox = tester.getRect(find.byType(AppBottomNavBar));
        expect(navBox.left + 16, closeTo(expectedLeft, 1));
        expect(navBox.right - 16, closeTo(expectedRight, 1));

        // A dua row is one of those self-padded sections.
        final tile = tester.getRect(find.byType(DuaItemTile).first);
        expect(
          tile.left,
          closeTo(expectedLeft, 1),
          reason: 'the rows start inside the pill at ${width}px',
        );
        expect(tile.right, closeTo(expectedRight, 1));
      });

      testWidgets('a padded page at ${width.toInt()}px', (tester) async {
        final padding = await pagePadding(tester, width);
        final (left, right) = pillEdges(width);
        expect(padding.left, closeTo(left, 1), reason: '${width}px');
        expect(padding.right, closeTo(width - right, 1), reason: '${width}px');
        // And the column it leaves is the whole cap, never short of it.
        expect(
          width - padding.horizontal,
          closeTo(
            width > DuaLayout.maxNav ? DuaLayout.maxContent : width - 32,
            1,
          ),
          reason: '${width}px',
        );
      });
    }
  });

  group('the browser gets bigger type', () {
    test('a phone-width window is left exactly as it was', () {
      // Only a window with room to spare grows its type; a phone browser,
      // and the 600px column other routes still use, are untouched.
      for (final width in [320.0, 375.0, 430.0, 600.0, 719.0]) {
        expect(DuaLayout.textScale(width), 1.0, reason: '${width}px');
      }
    });

    test('each step up in window width is a step up in type', () {
      final steps = [
        DuaLayout.textScale(700),
        DuaLayout.textScale(DuaLayout.wide),
        DuaLayout.textScale(DuaLayout.extraWide),
        DuaLayout.textScale(DuaLayout.ultraWide),
      ];
      expect(steps, orderedEquals(<double>[...steps]..sort()));
      expect(steps.first, 1.0);
      expect(steps.last, greaterThan(1.2));
    });

    testWidgets('a category title is bigger on a full-screen window', (
      tester,
    ) async {
      // One line of a tile's title, so the height measured is the type's.
      Future<double> titleHeight(double width) async {
        await pumpAt(
          tester,
          DuaAllCategoryScreen(repository: _Repo()),
          width,
          webUnits: true,
        );
        expect(tester.takeException(), isNull);
        return tester
            .getSize(find.textContaining('Protection & Ruqyah').first)
            .height;
      }

      final phone = await titleHeight(375);
      final desktop = await titleHeight(1600);
      expect(
        desktop,
        greaterThan(phone * 1.2),
        reason:
            'a 13-19px phone type stayed that size on a monitor: '
            '$phone -> $desktop',
      );
    });

    testWidgets('the reader keeps its own font-size setting on top', (
      tester,
    ) async {
      // `DuaWebTypography` multiplies the scaler already in force (the
      // reader's `appFontScale` preference), so the setting still moves the
      // type it always moved.
      late double scaled;
      tester.view.physicalSize = const Size(1600 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(1600, 900),
            textScaler: TextScaler.linear(1.2),
          ),
          child: DuaWebTypography(
            enabled: true,
            child: Builder(
              builder: (context) {
                scaled = MediaQuery.textScalerOf(context).scale(10);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(scaled, closeTo(10 * 1.2 * DuaLayout.textScale(1600), 0.01));
    });

    testWidgets('a fixed box grows with the type it holds', (tester) async {
      // A grid tile's height is a fixed extent; left alone it would clip the
      // bigger title.
      Future<double> tileHeight(double width) async {
        await pumpAt(
          tester,
          DuaAllCategoryScreen(repository: _Repo()),
          width,
          webUnits: true,
        );
        expect(tester.takeException(), isNull);
        return tester.getSize(find.byType(DuaCategoryTile).first).height;
      }

      final phone = await tileHeight(375);
      final desktop = await tileHeight(1600);
      expect(desktop, greaterThan(phone));
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
