import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/navigation/amol_tracker_navigation.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/screens/amol_tracking_screen.dart';
import 'package:tuhfatul_muslim/features/home/presentation/screens/home_screen.dart';

Future<void> _pumpHome(WidgetTester tester, Widget body) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(home: Scaffold(body: body)),
    ),
  );
}

void main() {
  group('HomeGradientShape whole-card tap', () {
    testWidgets('a tap on an empty corner of the card fires onTap', (
      tester,
    ) async {
      var taps = 0;
      await _pumpHome(
        tester,
        Center(
          child: HomeGradientShape(
            onTap: () => taps++,
            child: const SizedBox.expand(),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(HomeGradientShape));
      await tester.tapAt(rect.topLeft + const Offset(20, 20));
      await tester.tapAt(rect.bottomRight - const Offset(20, 20));
      expect(taps, 2);
    });

    testWidgets('an inner button keeps its own tap and does not open twice', (
      tester,
    ) async {
      var cardTaps = 0;
      var buttonTaps = 0;
      await _pumpHome(
        tester,
        Center(
          child: HomeGradientShape(
            onTap: () => cardTaps++,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => buttonTaps++,
                child: const SizedBox(width: 60, height: 40, key: Key('pill')),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('pill')));
      expect(buttonTaps, 1);
      expect(cardTaps, 0);
    });

    testWidgets('without onTap the card ignores taps', (tester) async {
      await _pumpHome(
        tester,
        const Center(child: HomeGradientShape(child: SizedBox.expand())),
      );
      await tester.tap(find.byType(HomeGradientShape));
      expect(tester.takeException(), isNull);
    });
  });

  group('openAmolTracker', () {
    testWidgets('a burst of taps opens exactly one screen', (tester) async {
      var built = 0;
      late BuildContext context;
      await _pumpHome(
        tester,
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );

      for (var i = 0; i < 4; i++) {
        openAmolTracker(
          context,
          section: AmalSection.fardhPrayer,
          builder: (_) {
            built++;
            return const Scaffold(body: Text('tracker'));
          },
        );
      }
      await tester.pumpAndSettle();

      expect(find.text('tracker'), findsOneWidget);
      expect(built, 1);

      // Once it is closed, the next tap opens a tracker again.
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      expect(find.text('tracker'), findsNothing);
      openAmolTracker(
        context,
        section: AmalSection.fardhPrayer,
        builder: (_) => const Scaffold(body: Text('tracker')),
      );
      await tester.pumpAndSettle();
      expect(find.text('tracker'), findsOneWidget);

      // Close it, so the guard is released for whatever runs next.
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('the screen fades in rather than appearing at once', (
      tester,
    ) async {
      late BuildContext context;
      await _pumpHome(
        tester,
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      openAmolTracker(
        context,
        section: AmalSection.quran,
        builder: (_) => const Scaffold(body: Text('tracker')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('tracker'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
    });
  });
}
