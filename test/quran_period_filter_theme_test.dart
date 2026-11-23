import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/quran_text.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/dashboard/quran_period_dropdown.dart';

/// Puts the filter on screen under an explicit [brightness].
///
/// A `Theme` rather than `MaterialApp.themeMode`: MaterialApp animates a
/// theme change, so a single pump would still report the light brightness.
Future<void> _pump(
  WidgetTester tester, {
  required Brightness brightness,
  QuranHistoryPeriod period = QuranHistoryPeriod.daily,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        home: Theme(
          data: ThemeData(brightness: brightness),
          child: Scaffold(
            body: Center(
              child: QuranPeriodDropdown(
                period: period,
                month: null,
                labelFor: (p) => switch (p) {
                  QuranHistoryPeriod.daily => 'Daily',
                  QuranHistoryPeriod.weekly => 'Weekly',
                  QuranHistoryPeriod.monthly => 'Monthly',
                },
                onChanged: (_, {month}) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

PopupMenuButton<void> _button(WidgetTester tester) =>
    tester.widget<PopupMenuButton<void>>(find.byType(PopupMenuButton<void>));

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byType(PopupMenuButton<void>));
  await tester.pumpAndSettle();
}

Finder _inMenu(Finder matching) =>
    find.descendant(of: find.byType(PopupMenuItem<void>), matching: matching);

/// The fill behind a period row, or null when that row is not highlighted.
Color? _rowBand(WidgetTester tester, String label) {
  final bands = tester
      .widgetList<Container>(
        find.ancestor(
          of: _inMenu(find.text(label)),
          matching: find.byType(Container),
        ),
      )
      .where((c) => c.color != null && c.color != Colors.transparent);
  return bands.isEmpty ? null : bands.first.color;
}

Color _monthInk(WidgetTester tester, int month) => tester
    .widget<Text>(_inMenu(find.text(QuranText.english.monthShort(month))))
    .style!
    .color!;

void main() {
  group('the filter card', () {
    testWidgets('is white in light mode and a dark surface in dark mode', (
      tester,
    ) async {
      await _pump(tester, brightness: Brightness.light);
      expect(_button(tester).color, Colors.white);

      await _pump(tester, brightness: Brightness.dark);
      final dark = _button(tester).color!;
      expect(dark, isNot(Colors.white));
      // Dark enough for the menu's own light ink to read on it.
      expect(dark.computeLuminance(), lessThan(0.1));
    });

    testWidgets('is outlined in dark mode, where its shadow cannot be seen', (
      tester,
    ) async {
      await _pump(tester, brightness: Brightness.light);
      expect(
        (_button(tester).shape! as RoundedRectangleBorder).side.style,
        BorderStyle.none,
      );

      await _pump(tester, brightness: Brightness.dark);
      final side = (_button(tester).shape! as RoundedRectangleBorder).side;
      expect(side.style, BorderStyle.solid);
      expect(side.color, AppColor.darkBorder);
    });
  });

  group('the picked period', () {
    testWidgets('keeps its light green band in light mode', (tester) async {
      await _pump(tester, brightness: Brightness.light);
      await _openMenu(tester);

      expect(_rowBand(tester, 'Daily'), const Color(0xFFEDF3D6));
      expect(_rowBand(tester, 'Weekly'), isNull);
    });

    testWidgets('is marked with a band that stands out from the dark card', (
      tester,
    ) async {
      await _pump(
        tester,
        brightness: Brightness.dark,
        period: QuranHistoryPeriod.weekly,
      );
      await _openMenu(tester);

      final band = _rowBand(tester, 'Weekly');
      expect(band, isNotNull);
      expect(band, isNot(const Color(0xFFEDF3D6)));
      expect(_rowBand(tester, 'Daily'), isNull);

      // Visibly lighter than the card it sits on, or the pick is invisible.
      final card = _button(tester).color!;
      expect(
        band!.computeLuminance(),
        greaterThan(card.computeLuminance() + 0.01),
      );
    });

    testWidgets('reads as text, not as ink on a light band', (tester) async {
      await _pump(tester, brightness: Brightness.dark);
      await _openMenu(tester);

      final ink = tester
          .widget<Text>(_inMenu(find.text('Daily')))
          .style!
          .color!;
      expect(ink.computeLuminance(), greaterThan(0.4));
    });
  });

  group('the month grid', () {
    testWidgets('dims a month that has not happened yet in dark mode', (
      tester,
    ) async {
      final now = DateTime.now();
      // Every month is reachable in December, so there is nothing to dim.
      if (now.month == 12) return;

      await _pump(
        tester,
        brightness: Brightness.dark,
        period: QuranHistoryPeriod.monthly,
      );
      await _openMenu(tester);

      final reachable = _monthInk(tester, now.month);
      final future = _monthInk(tester, now.month + 1);
      expect(future.a, lessThan(reachable.a));
      expect(reachable.computeLuminance(), greaterThan(0.4));
    });

    testWidgets('keeps the designed greys in light mode', (tester) async {
      final now = DateTime.now();
      if (now.month == 12) return;

      await _pump(
        tester,
        brightness: Brightness.light,
        period: QuranHistoryPeriod.monthly,
      );
      await _openMenu(tester);

      expect(_monthInk(tester, now.month), const Color(0xFF2C3320));
      expect(_monthInk(tester, now.month + 1), const Color(0xFFB4B9A6));
    });
  });
}
