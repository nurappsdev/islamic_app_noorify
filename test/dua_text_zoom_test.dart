import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    /// [tall] adds filler segments, so the page is longer than the screen
    /// and has somewhere to scroll.
    Future<void> pump(WidgetTester tester, {bool tall = false}) async {
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
                  detail: DuaDetail(
                    name: title,
                    segments: [
                      const DuaSegment(
                        arabic: arabic,
                        translation: translation,
                      ),
                      if (tall)
                        for (var i = 0; i < 8; i++)
                          DuaSegment(
                            arabic: 'filler arabic $i',
                            translation: 'filler translation $i ' * 6,
                          ),
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

    /// A fixed label, such as the title: still a plain [Text].
    double sizeOf(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text)).style!.fontSize!;

    /// The reading texts are [SelectableText], which `find.text` — a [Text]
    /// matcher — does not see.
    Finder readingText(String text) => find.byWidgetPredicate(
      (widget) => widget is SelectableText && widget.data == text,
      description: 'SelectableText("$text")',
    );

    double readingSizeOf(WidgetTester tester, String text) =>
        tester.widget<SelectableText>(readingText(text)).style!.fontSize!;

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
        for (final text in [arabic, pronunciation, translation])
          text: readingSizeOf(tester, text),
      };
      final titleBefore = sizeOf(tester, title);

      await pinchOut(tester);

      // Twice the finger distance, twice the reading size.
      expect(readingSizeOf(tester, arabic), closeTo(before[arabic]! * 2, 0.5));
      expect(
        readingSizeOf(tester, pronunciation),
        closeTo(before[pronunciation]! * 2, 0.5),
      );
      expect(
        readingSizeOf(tester, translation),
        closeTo(before[translation]! * 2, 0.5),
      );
      // The title is not reading text.
      expect(sizeOf(tester, title), titleBefore);
    });

    testWidgets('the size reached outlives the gesture', (tester) async {
      await pump(tester);
      await pinchOut(tester);
      final zoomed = readingSizeOf(tester, arabic);

      // Several frames on from the commit: still the size it was let go at.
      await tester.pump(const Duration(seconds: 1));
      expect(readingSizeOf(tester, arabic), zoomed);
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
      expect(readingSizeOf(tester, arabic), DuaFontSizeLimits.arabicMax);
      expect(
        readingSizeOf(tester, translation),
        DuaFontSizeLimits.translationMax,
      );
    });

    testWidgets('each reading text can be selected, the rest cannot', (
      tester,
    ) async {
      await pump(tester);

      for (final text in [arabic, pronunciation, translation]) {
        expect(readingText(text), findsOneWidget, reason: text);
      }
      // The title and the category label stay plain text.
      expect(find.text(title), findsOneWidget);
      expect(readingText(title), findsNothing);
    });

    testWidgets('a long press selects a word and the menu copies it', (
      tester,
    ) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pump(tester);

      await tester.longPress(readingText(translation));
      await tester.pumpAndSettle();

      // The platform's own menu, with a word of the translation selected.
      expect(find.text('Copy'), findsOneWidget);
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      expect(copied, hasLength(1));
      expect(copied.single, isNotEmpty);
      expect(translation, contains(copied.single));
    });

    testWidgets('a pinch started on the selectable text still zooms', (
      tester,
    ) async {
      await pump(tester);
      final before = readingSizeOf(tester, translation);
      // Both fingers inside the translation, which has its own long-press
      // and tap recognizers in the arena.
      final center = tester.getCenter(readingText(translation));

      final first = await tester.startGesture(
        center - const Offset(30, 0),
        pointer: 1,
      );
      final second = await tester.startGesture(
        center + const Offset(30, 0),
        pointer: 2,
      );
      await tester.pump();
      await first.moveBy(const Offset(-30, 0));
      await second.moveBy(const Offset(30, 0));
      await tester.pump();
      await first.up();
      await second.up();
      await tester.pumpAndSettle();

      expect(readingSizeOf(tester, translation), closeTo(before * 2, 0.5));
      // A pinch is not a long press: no selection menu came up.
      expect(find.text('Copy'), findsNothing);
    });

    testWidgets('a drag over the reading text still scrolls the page', (
      tester,
    ) async {
      await pump(tester, tall: true);
      final before = tester.getTopLeft(readingText(translation)).dy;

      await tester.drag(readingText(translation), const Offset(0, -150));
      await tester.pumpAndSettle();

      // Selectable text brings its own viewport, which must not swallow the
      // drag: the page is what moves, by the distance dragged less the slop
      // the gesture spends before the scroll starts.
      expect(
        tester.getTopLeft(readingText(translation)).dy,
        lessThan(before - 100),
      );
    });
  });
}
