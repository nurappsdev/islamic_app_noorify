import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_design.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_page_viewport.dart';

void main() {
  Widget page({
    String? zoom,
    double magnify = 1,
    VoidCallback? onNext,
    VoidCallback? onPrevious,
  }) => MaterialApp(
    home: Scaffold(
      body: QuranPageViewport(
        pageNumber: 2,
        footer: const SizedBox(),
        zoomLabel: zoom,
        magnify: magnify,
        onNext: onNext,
        onPrevious: onPrevious,
        child: const SizedBox(height: 400, child: Text('Ayahs')),
      ),
    ),
  );

  double opacityOf(WidgetTester tester, Finder finder) => tester
      .widget<AnimatedOpacity>(
        find.ancestor(of: finder, matching: find.byType(AnimatedOpacity)),
      )
      .opacity;

  testWidgets('the zoom shows while pinching, then fades', (tester) async {
    final pill = find.byKey(const ValueKey('quran-zoom-pill'));
    await tester.pumpWidget(page());
    expect(opacityOf(tester, pill), 0, reason: 'no pinch, no pill');

    await tester.pumpWidget(page(zoom: '120%'));
    expect(find.text('120%'), findsOneWidget);
    expect(opacityOf(tester, pill), 1);
    await tester.pumpWidget(page(zoom: '135%'));
    expect(find.text('135%'), findsOneWidget);

    // Pinch over: the last zoom stays a moment, then goes.
    await tester.pumpWidget(page());
    expect(find.text('135%'), findsOneWidget);
    expect(opacityOf(tester, pill), 1);
    await tester.pump(const Duration(seconds: 1));
    expect(opacityOf(tester, pill), 0);
  });

  testWidgets('a swipe shows which way the page turns', (tester) async {
    var next = 0;
    await tester.pumpWidget(page(onNext: () => next++));
    final indicator = find.byKey(const ValueKey('quran-swipe-indicator'));
    final center = tester.getCenter(find.byType(QuranPageViewport));

    // Right (forward, like an Arabic book): it comes in at the left.
    final drag = await tester.startGesture(center);
    await drag.moveBy(const Offset(30, 0));
    await drag.moveBy(const Offset(10, 0));
    await tester.pump();
    expect(indicator, findsOneWidget);
    expect(tester.getCenter(indicator).dx, lessThan(center.dx));
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    await drag.moveBy(const Offset(40, 0));
    await tester.pump(const Duration(milliseconds: 200));
    final ready = tester.widget<AnimatedContainer>(indicator);
    expect(
      (ready.decoration! as BoxDecoration).color,
      quranOlive,
      reason: 'far enough to turn: filled',
    );
    await drag.up();
    await tester.pumpAndSettle();
    expect(next, 1);
    expect(indicator, findsNothing, reason: 'gone once the finger lifts');

    // Left (back) with no page before: nothing shows.
    final back = await tester.startGesture(center);
    await back.moveBy(const Offset(-30, 0));
    await back.moveBy(const Offset(-30, 0));
    await tester.pump();
    expect(indicator, findsNothing);
    await back.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a pinch magnifies the page as one picture', (tester) async {
    double scaleOf() => tester
        .widget<Transform>(find.byKey(const ValueKey('quran-page-magnify')))
        .transform
        .getMaxScaleOnAxis();
    final text = find.text('Ayahs');
    await tester.pumpWidget(page());
    expect(scaleOf(), 1);
    final laidOut = tester.getSize(text);
    final drawn = tester.getRect(text).width;
    await tester.pumpWidget(page(magnify: 1.3));
    expect(scaleOf(), moreOrLessEquals(1.3));
    // Laid out as before; only the picture of it grows.
    expect(tester.getSize(text), laidOut);
    expect(tester.getRect(text).width, moreOrLessEquals(drawn * 1.3));
  });

  testWidgets('drawn smaller mid-pinch, every line stays in the frame', (
    tester,
  ) async {
    Widget full(double magnify) => MaterialApp(
      home: Scaffold(
        body: QuranPageViewport(
          pageNumber: 2,
          footer: const SizedBox(),
          magnify: magnify,
          child: const SizedBox(
            height: 400,
            width: double.infinity,
            child: ColoredBox(color: Colors.amber, key: ValueKey('text')),
          ),
        ),
      ),
    );
    final frame = find.byKey(const ValueKey('quran-frame-interior'));
    final text = find.byKey(const ValueKey('text'));
    await tester.pumpWidget(full(1));
    final inside = tester.getRect(frame);
    await tester.pumpWidget(full(.96));
    final drawn = tester.getRect(text);
    expect(drawn.left, greaterThanOrEqualTo(inside.left));
    expect(drawn.right, lessThanOrEqualTo(inside.right));
  });

  testWidgets('line ends may sweep past the text into the frame margin', (
    tester,
  ) async {
    // Nastaleeq letters ending a line are drawn past its edge; the frame
    // must not clip them, at any zoom.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranPageViewport(
            pageNumber: 2,
            footer: const SizedBox(),
            child: const SizedBox(
              height: 400,
              width: double.infinity,
              child: ColoredBox(color: Colors.amber, key: ValueKey('text')),
            ),
          ),
        ),
      ),
    );
    final clip = tester.getRect(
      find.byKey(const ValueKey('quran-frame-interior')),
    );
    final text = tester.getRect(find.byKey(const ValueKey('text')));
    expect(text.left - clip.left, greaterThanOrEqualTo(20));
    expect(clip.right - text.right, greaterThanOrEqualTo(20));
  });
}
