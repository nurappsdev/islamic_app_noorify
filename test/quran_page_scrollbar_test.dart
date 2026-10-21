import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_page_viewport.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, double height) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranPageViewport(
              pageNumber: 2,
              footer: const SizedBox(),
              child: SizedBox(
                height: height,
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: Text('Ayahs'),
                ),
              ),
            ),
          ),
        ),
      );

  final scrollbar = find.byKey(const ValueKey('quran-page-scrollbar'));

  testWidgets('a long page shows its thumb while scrolling, then fades', (
    tester,
  ) async {
    await pumpPage(tester, 3000);
    expect(scrollbar, isNot(paints..rrect()), reason: 'hidden at rest');

    final drag = await tester.startGesture(tester.getCenter(scrollbar));
    for (var i = 0; i < 10; i++) {
      await drag.moveBy(const Offset(0, -30));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(scrollbar, paints..rrect());
    await drag.up();

    // It starts to fade a moment after the scroll stops.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(scrollbar, isNot(paints..rrect()), reason: 'faded once stopped');
  });

  testWidgets('the thumb has a gutter of its own beside the text', (
    tester,
  ) async {
    await pumpPage(tester, 3000);
    final text = tester.getRect(find.byType(SizedBox).last);
    final page = tester.getRect(scrollbar);
    expect(page.right - text.right, greaterThanOrEqualTo(8));
  });
}
