import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_page_viewport.dart';

void main() {
  testWidgets('Surah opening omits the upper ornament', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuranPageViewport(
            pageNumber: 1,
            showHeader: false,
            footer: SizedBox(),
            child: Text('Opening'),
          ),
        ),
      ),
    );
    final assets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName);
    expect(assets, isNot(contains('assets/images/quran/header.png')));
    expect(assets, contains('assets/images/quran/footer.png'));
  });
  testWidgets(
    'swipes animate adjacent pages; vertical scrolling stays clipped',
    (tester) async {
      var page = 2;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) => QuranPageViewport(
                pageNumber: page,
                onNext: page < 4 ? () => update(() => page++) : null,
                onPrevious: page > 2 ? () => update(() => page--) : null,
                footer: const Text('Fixed footer'),
                child: SizedBox(height: 2000, child: Text('Content $page')),
              ),
            ),
          ),
        ),
      );
      final interior = find.byKey(const ValueKey('quran-frame-interior'));
      expect(tester.widget<ClipRect>(interior).clipBehavior, Clip.hardEdge);
      final footerRect = tester.getRect(find.text('Fixed footer'));
      await tester.drag(interior, const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(page, 2);
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        greaterThan(0),
      );
      expect(tester.getRect(find.text('Fixed footer')), footerRect);
      await tester.drag(interior, const Offset(200, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(page, 3);
      expect(find.text('Content 2'), findsOneWidget);
      expect(find.text('Content 3'), findsOneWidget);
      expect(
        find.descendant(of: interior, matching: find.byType(SlideTransition)),
        findsNWidgets(2),
      );
      await tester.pumpAndSettle();
      expect(find.text('Content 2'), findsNothing);
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        0,
      );
      await tester.drag(interior, const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(page, 2);
      await tester.drag(interior, const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(page, 2);
      expect(find.byTooltip('Next page'), findsNothing);
      expect(find.byTooltip('Previous page'), findsNothing);
      expect(find.text('Page 2'), findsNothing);
      await tester.drag(interior, const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(page, 3);
      await tester.drag(interior, const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(page, 4);
      await tester.drag(interior, const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(page, 4);
      expect(tester.takeException(), isNull);
    },
  );
}
