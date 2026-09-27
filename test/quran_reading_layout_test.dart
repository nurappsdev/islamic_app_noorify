import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_reading_layout.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_page_viewport.dart';

void main() {
  testWidgets('idle controls collapse, preserve player, and reveal on swipe', (
    tester,
  ) async {
    var next = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranReadingLayout(
            top: const SizedBox(height: 80, child: Text('Filters and timer')),
            bottom: const SizedBox(height: 100, child: Text('Player')),
            page: QuranPageViewport(
              pageNumber: 2,
              footer: const SizedBox(),
              onNext: () => next++,
              child: const SizedBox(height: 2000, child: Text('Ayahs')),
            ),
          ),
        ),
      ),
    );
    final page = find.byType(QuranPageViewport);
    final initialHeight = tester.getSize(page).height;
    final playerElement = tester.element(find.text('Player'));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.getSize(page).height, initialHeight + 180);
    expect(tester.element(find.text('Player')), same(playerElement));
    expect(find.text('Player').hitTestable(), findsNothing);
    await tester.drag(page, const Offset(-150, 0));
    await tester.pumpAndSettle();
    expect(next, 1);
    expect(tester.getSize(page).height, initialHeight);
    expect(find.text('Player').hitTestable(), findsOneWidget);
    // Holding a finger on the page must not start another idle timeout.
    final gesture = await tester.startGesture(tester.getCenter(page));
    await tester.pump(const Duration(seconds: 6));
    expect(tester.getSize(page).height, initialHeight);
    await gesture.up();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.getSize(page).height, initialHeight + 180);
    // Vertical scrolling reveals controls without triggering a page turn.
    await tester.drag(page, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(next, 1);
    expect(tester.getSize(page).height, initialHeight);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
