import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/dua_catalog.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_reader_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_text_zoom.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

void main() {
  setUpAll(() async => AppText.load());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the pinch factor', () {
    test('leaves the sizes alone at rest', () {
      final sizes = duaZoomedFontSizes(arabic: 20, translation: 12, scale: 1);
      expect(sizes.arabic, 20);
      expect(sizes.translation, 12);
    });

    test('moves both sizes by the same factor', () {
      final sizes = duaZoomedFontSizes(arabic: 20, translation: 12, scale: 1.5);
      expect(sizes.arabic, 30);
      expect(sizes.translation, 18);
    });

    test('stops at the sliders\' largest sizes', () {
      final sizes = duaZoomedFontSizes(arabic: 20, translation: 12, scale: 9);
      expect(sizes.arabic, DuaFontSizeLimits.arabicMax);
      expect(sizes.translation, DuaFontSizeLimits.translationMax);
    });

    test('stops at the sliders\' smallest sizes', () {
      final sizes = duaZoomedFontSizes(arabic: 20, translation: 12, scale: 0.1);
      // Translation runs out of room first, and holds the Arabic with it.
      expect(sizes.translation, DuaFontSizeLimits.translationMin);
      expect(sizes.arabic, closeTo(16.67, 0.01));
      expect(sizes.arabic, greaterThanOrEqualTo(DuaFontSizeLimits.arabicMin));
    });

    test('a size stored outside the limits is brought back in', () {
      final sizes = duaZoomedFontSizes(arabic: 200, translation: 1, scale: 1);
      expect(sizes.arabic, DuaFontSizeLimits.arabicMax);
      expect(sizes.translation, DuaFontSizeLimits.translationMin);
    });

    test('a factor that is no number changes nothing', () {
      for (final scale in [0.0, -1.0, double.nan, double.infinity]) {
        final sizes = duaZoomedFontSizes(
          arabic: 20,
          translation: 12,
          scale: scale,
        );
        expect(sizes.arabic, 20, reason: 'scale $scale');
        expect(sizes.translation, 12, reason: 'scale $scale');
      }
    });
  });

  group('the two-finger detector', () {
    late List<double> zooms;
    late int starts;
    late int ends;
    late ScrollController controller;
    late int taps;

    Widget build() {
      zooms = [];
      starts = 0;
      ends = 0;
      taps = 0;
      controller = ScrollController();
      return MaterialApp(
        home: Scaffold(
          body: DuaTextZoomDetector(
            onZoomStart: () => starts++,
            onZoomUpdate: zooms.add,
            onZoomEnd: () => ends++,
            child: ListView(
              controller: controller,
              children: [
                TextButton(onPressed: () => taps++, child: const Text('copy')),
                for (var i = 0; i < 20; i++)
                  SizedBox(height: 120, child: Text('line $i')),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('a pinch reports the factor and the list stays put', (
      tester,
    ) async {
      await tester.pumpWidget(build());
      final center = tester.getCenter(find.byType(ListView));

      final first = await tester.startGesture(
        center - const Offset(0, 40),
        pointer: 1,
      );
      final second = await tester.startGesture(
        center + const Offset(0, 40),
        pointer: 2,
      );
      await tester.pump();
      // 80 logical pixels apart, then 160: twice the size.
      await first.moveBy(const Offset(0, -40));
      await second.moveBy(const Offset(0, 40));
      await tester.pump();

      expect(starts, 1);
      expect(zooms.last, closeTo(2, 0.01));
      expect(controller.offset, 0, reason: 'the list must not scroll');

      await first.up();
      await second.up();
      await tester.pump();
      expect(ends, 1);
    });

    testWidgets('one finger still scrolls the list and zooms nothing', (
      tester,
    ) async {
      await tester.pumpWidget(build());

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(controller.offset, greaterThan(100));
      expect(zooms, isEmpty);
      expect(starts, 0);
    });

    testWidgets('a button under the detector is still tappable', (
      tester,
    ) async {
      await tester.pumpWidget(build());

      await tester.tap(find.text('copy'));
      await tester.pump();

      expect(taps, 1);
      expect(zooms, isEmpty);
    });

    testWidgets('lifting one finger holds the size it reached', (tester) async {
      await tester.pumpWidget(build());
      final center = tester.getCenter(find.byType(ListView));

      final first = await tester.startGesture(
        center - const Offset(0, 40),
        pointer: 1,
      );
      final second = await tester.startGesture(
        center + const Offset(0, 40),
        pointer: 2,
      );
      await tester.pump();
      await first.moveBy(const Offset(0, -40));
      await second.moveBy(const Offset(0, 40));
      await tester.pump();
      final reached = zooms.last;

      // One finger has no span to measure: nothing further is reported.
      await second.up();
      await tester.pump();
      await first.moveBy(const Offset(0, -60));
      await tester.pump();

      expect(zooms.last, reached);
      await first.up();
      await tester.pump();
      expect(ends, 1);
    });
  });

  group('the reader screen', () {
    const arabic = 'ARABIC LINE';
    const pronunciation = 'BANGLA PRONUNCIATION';
    const translation = 'BANGLA TRANSLATION';
    // Longer than the 12 characters the header shows, so the heading below
    // it is the only widget carrying the whole title.
    const title = 'Dua For Testing Zoom';

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => LanguageBloc(initialLanguage: AppLanguage.bangla),
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              home: DuaReaderScreen(
                args: DuaReaderArgs.mock(
                  featured: DuaCatalog.featured.first,
                  detail: const DuaDetail(
                    name: title,
                    segments: [
                      DuaSegment(arabic: arabic, translation: translation),
                    ],
                    transliteration: pronunciation,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    double sizeOf(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text)).style!.fontSize!;

    /// Spreads two fingers over the reader to twice their distance.
    Future<void> pinchOut(WidgetTester tester) async {
      final center = tester.getCenter(find.byType(ListView));
      final first = await tester.startGesture(
        center - const Offset(0, 40),
        pointer: 1,
      );
      final second = await tester.startGesture(
        center + const Offset(0, 40),
        pointer: 2,
      );
      await tester.pump();
      await first.moveBy(const Offset(0, -40));
      await second.moveBy(const Offset(0, 40));
      await tester.pump();
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
    }

    testWidgets('a pinch grows the three reading texts only', (tester) async {
      await pump(tester);

      final before = {
        for (final text in [arabic, pronunciation, translation, title])
          text: sizeOf(tester, text),
      };

      await pinchOut(tester);

      // Twice the finger distance, twice the reading size.
      expect(sizeOf(tester, arabic), closeTo(before[arabic]! * 2, 0.5));
      expect(
        sizeOf(tester, pronunciation),
        closeTo(before[pronunciation]! * 2, 0.5),
      );
      expect(
        sizeOf(tester, translation),
        closeTo(before[translation]! * 2, 0.5),
      );
      // The title is not reading text.
      expect(sizeOf(tester, title), before[title]);
    });

    testWidgets('the size reached outlives the gesture', (tester) async {
      await pump(tester);
      await pinchOut(tester);
      final zoomed = sizeOf(tester, arabic);

      // Several frames on from the commit: still the size it was let go at.
      await tester.pump(const Duration(seconds: 1));
      expect(sizeOf(tester, arabic), zoomed);
    });

    testWidgets('a pinch beyond the limit stops at the largest size', (
      tester,
    ) async {
      await pump(tester);

      for (var i = 0; i < 4; i++) {
        await pinchOut(tester);
      }

      // 20px scaled by 2 four times would be 320px; the slider's ceiling is
      // 50px and the pinch obeys it.
      expect(sizeOf(tester, arabic), DuaFontSizeLimits.arabicMax);
      expect(sizeOf(tester, translation), DuaFontSizeLimits.translationMax);
    });
  });
}
