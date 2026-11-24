import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/dashboard/quran_dashboard_charts.dart';

const _size = Size(343, 245);

final _data = QuranChartData(
  labels: const ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
  mine: const [5, 8, 2, 10, 0, 14, 6],
  competitor: const [7, 3, 9, 30, 1, 4, 11],
  competitorBadge: 'RA',
  myPoints: const [1, 2, 0, 4, 0, 5, 2],
  competitorPoints: const [2, 1, 3, 2, 0, 1, 4],
  mySeconds: const [300, 480, 120, 600, 0, 840, 360],
  competitorSeconds: const [420, 180, 540, 1800, 60, 240, 660],
  myName: 'Ilm',
  competitorName: 'Rafi',
);

Future<void> _pumpWeekly(WidgetTester tester, {bool competitor = true}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: _size.width,
            height: _size.height,
            child: QuranWeeklyChart(data: _data, showCompetitor: competitor),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

QuranPlotArea get _area =>
    QuranPlotArea.bars(_size, _data.maxY, _data.labels.length);

/// Taps day [index] on its bar, where the chart actually draws it.
Future<void> _tapDay(WidgetTester tester, int index) async {
  final origin = tester.getTopLeft(find.byType(QuranWeeklyChart));
  final x = _area.xForIndex(index, _data.labels.length);
  // Just above the baseline, which is inside the bar however short it is.
  await tester.tapAt(origin + Offset(x, _area.bottom - 4));
  await tester.pumpAndSettle();
}

void main() {
  group('a tapped point opens its card', () {
    testWidgets('nothing is shown until a point is tapped', (tester) async {
      await _pumpWeekly(tester);

      expect(find.byType(QuranChartTooltip), findsNothing);
      expect(find.textContaining('Point :'), findsNothing);
      expect(find.text('Ilm'), findsNothing);
    });

    testWidgets('the tapped day shows both readers, time and points', (
      tester,
    ) async {
      await _pumpWeekly(tester);
      await _tapDay(tester, 3);

      expect(find.byType(QuranChartTooltip), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget); // the card's heading
      expect(find.text('Ilm'), findsOneWidget);
      expect(find.text('10 min'), findsOneWidget); // 600s
      expect(find.text('Point : 4'), findsOneWidget);
      expect(find.text('Rafi'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget); // 1800s
      expect(find.text('Point : 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping the same day again closes the card', (tester) async {
      await _pumpWeekly(tester);
      await _tapDay(tester, 3);
      expect(find.byType(QuranChartTooltip), findsOneWidget);

      await _tapDay(tester, 3);
      expect(find.byType(QuranChartTooltip), findsNothing);
    });

    testWidgets('with the competitor off only my own row is shown', (
      tester,
    ) async {
      await _pumpWeekly(tester, competitor: false);
      await _tapDay(tester, 3);

      expect(find.text('Ilm'), findsOneWidget);
      expect(find.text('Rafi'), findsNothing);
      expect(find.text('Point : 4'), findsOneWidget);
    });

    testWidgets('the card stays inside the chart at the last day', (
      tester,
    ) async {
      await _pumpWeekly(tester);
      await _tapDay(tester, 6);

      final card = tester.getRect(find.byType(QuranChartTooltip));
      final chart = tester.getRect(find.byType(QuranWeeklyChart));
      expect(card.left, greaterThanOrEqualTo(chart.left - 0.01));
      expect(card.right, lessThanOrEqualTo(chart.right + 0.01));
      expect(card.top, greaterThanOrEqualTo(chart.top - 0.01));
      expect(tester.takeException(), isNull);
    });
  });

  group('the week is drawn as bars', () {
    test('a day owns its whole slot, not just the middle of it', () {
      const count = 7;
      final area = QuranPlotArea.bars(_size, _data.maxY, count);
      for (var i = 0; i < count; i++) {
        final centre = area.xForIndex(i, count);
        expect(area.indexAt(centre, count), i);
        expect(area.indexAt(centre - area.slotWidth / 2 + .5, count), i);
        expect(area.indexAt(centre + area.slotWidth / 2 - .5, count), i);
      }
    });

    testWidgets('a tap anywhere in a day\'s slot opens that day', (
      tester,
    ) async {
      await _pumpWeekly(tester);
      final origin = tester.getTopLeft(find.byType(QuranWeeklyChart));
      // The left edge of Tuesday's slot, above its bar rather than on it.
      await tester.tapAt(
        origin +
            Offset(
              _area.xForIndex(3, 7) - _area.slotWidth / 2 + 1,
              _area.top + 4,
            ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Ilm'), findsOneWidget);
    });
  });

  group('the chart frame follows the theme', () {
    testWidgets('dark mode resolves its own axis, grid and day inks', (
      tester,
    ) async {
      // A plain Theme, not MaterialApp's themeMode: that one animates the
      // switch, so a single pump would still report the old brightness.
      Future<QuranChartPalette> paletteFor(ThemeData theme) async {
        late QuranChartPalette palette;
        await tester.pumpWidget(
          MaterialApp(
            home: Theme(
              data: theme,
              child: Builder(
                builder: (context) {
                  palette = QuranChartPalette.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        await tester.pump();
        return palette;
      }

      final light = await paletteFor(ThemeData.light());
      final dark = await paletteFor(ThemeData.dark());

      expect(dark, isNot(light));
      // Each role is mapped on its own, not one blanket colour.
      expect(dark.axisInk, isNot(light.axisInk));
      expect(dark.gridLine, isNot(light.gridLine));
      expect(dark.dayInk, isNot(light.dayInk));
    });

    testWidgets('the chart draws in dark mode without complaint', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: _size.width,
                height: _size.height,
                child: QuranWeeklyChart(data: _data),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await _tapDay(tester, 2);

      expect(find.byType(QuranChartTooltip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
