import 'package:flutter/gestures.dart' show DeviceGestureSettings;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/quran/domain/arabic_font.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_ayah.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_reading_text.dart';

void main() {
  testWidgets(
    'ayah markers reserve both side gaps at normal and enlarged sizes',
    (tester) async {
      int? tapped;
      final ayahs = [
        for (final n in [1, 3, 255])
          QuranAyah(
            surahNumber: 2,
            ayahNumber: n,
            verseKey: '2:$n',
            ayahIndex: n + 7,
            paraNumber: 1,
            pageNumber: 2,
            textArabic:
                'ذَٰلِكَ الْكِتَابُ لَا رَيْبَ فِيهِ هُدًى لِلْمُتَّقِينَ',
          ),
      ];
      for (final scale in [1.0, 2.5]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 280,
                  child: SingleChildScrollView(
                    child: QuranReadingText(
                      ayahs: ayahs,
                      active: 1,
                      scale: scale,
                      font: arabicFontById('noorehuda'),
                      onHold: (ayah) => tapped = ayah.ayahNumber,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        for (final ayah in ayahs) {
          final outer = tester.getRect(
            find.byKey(ValueKey('ayah-marker-${ayah.verseKey}')),
          );
          final inner = tester.getRect(
            find.text(
              ayah.ayahNumber
                  .toString()
                  .split('')
                  .map((n) => String.fromCharCode(0x660 + int.parse(n)))
                  .join(),
            ),
          );
          expect(
            inner.left - outer.left,
            greaterThanOrEqualTo(10 * scale - .01),
          );
          expect(
            outer.right - inner.right,
            greaterThanOrEqualTo(10 * scale - .01),
          );
          expect(outer.left, greaterThanOrEqualTo(0));
        }
        await tester.ensureVisible(find.text('٣'));
        await tester.longPress(find.text('٣'));
        await tester.pump(kAyahHoldDuration);
        expect(tapped, 3);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('ayah details open only after a held press, with visible feedback', (
    tester,
  ) async {
    int? held;
    const ayah = QuranAyah(
      surahNumber: 2,
      ayahNumber: 3,
      verseKey: '2:3',
      ayahIndex: 10,
      paraNumber: 1,
      pageNumber: 2,
      textArabic: 'ذَٰلِكَ الْكِتَابُ',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranReadingText(
            ayahs: const [ayah],
            active: 0,
            scale: 1,
            font: arabicFontById('noorehuda'),
            onHold: (a) => held = a.ayahNumber,
          ),
        ),
      ),
    );
    final marker = find.byKey(const ValueKey('ayah-marker-2:3'));

    await tester.tap(marker);
    await tester.pump();
    expect(held, isNull);

    // The press shows at once and builds up; an early release undoes it.
    double markerScale() => tester
        .widget<Transform>(
          find.ancestor(of: marker, matching: find.byType(Transform)).first,
        )
        .transform
        .getMaxScaleOnAxis();
    final early = await tester.startGesture(tester.getCenter(marker));
    await tester.pump();
    await tester.pump(kAyahHoldDuration ~/ 2);
    expect(markerScale(), greaterThan(1));
    await early.up();
    await tester.pumpAndSettle();
    expect(markerScale(), 1);
    expect(held, isNull);

    final press = await tester.startGesture(tester.getCenter(marker));
    await tester.pump(kAyahHoldDuration - const Duration(milliseconds: 100));
    expect(held, isNull);
    await tester.pump(const Duration(milliseconds: 200));
    expect(held, 3);
    await press.up();
  });

  group('ayah press feedback', () {
    const ayahs = [
      QuranAyah(
        surahNumber: 2,
        ayahNumber: 3,
        verseKey: '2:3',
        ayahIndex: 10,
        paraNumber: 1,
        pageNumber: 2,
        textArabic: 'ذَٰلِكَ الْكِتَابُ',
      ),
    ];

    Future<List<int>> pump(
      WidgetTester tester, {
      int active = 0,
      ThemeMode theme = ThemeMode.light,
    }) async {
      final held = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: theme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  QuranReadingText(
                    ayahs: ayahs,
                    active: active,
                    scale: 1,
                    font: arabicFontById('noorehuda'),
                    onHold: (a) => held.add(a.ayahNumber),
                  ),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ),
        ),
      );
      return held;
    }

    Color? ayahTint(WidgetTester tester) {
      final root = tester.widget<RichText>(find.byType(RichText).first).text;
      return ((root as TextSpan).children!.first as TextSpan)
          .style
          ?.backgroundColor;
    }

    final marker = find.byKey(const ValueKey('ayah-marker-2:3'));

    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('pressing a playing ayah shows over it and returns '
          '(${theme.name})', (tester) async {
        await pump(tester, active: 3, theme: theme);
        final playing = ayahTint(tester);
        expect(playing, isNotNull);

        final press = await tester.startGesture(tester.getCenter(marker));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        final onTouch = ayahTint(tester);
        expect(onTouch, isNot(playing));
        await tester.pump(const Duration(milliseconds: 450));
        final deeper = ayahTint(tester)!;
        expect(deeper.a, greaterThan(onTouch!.a));
        // Still well short of opaque, so the Arabic stays readable.
        expect(deeper.a, lessThan(.6));

        await press.up();
        await tester.pumpAndSettle();
        expect(ayahTint(tester), playing);
      });
    }

    testWidgets('a real drag cancels the pending hold', (tester) async {
      final held = await pump(tester);
      final press = await tester.startGesture(tester.getCenter(marker));
      await tester.pump(const Duration(milliseconds: 200));
      await press.moveBy(const Offset(0, -60));
      await tester.pump(kAyahHoldDuration);
      await press.up();
      await tester.pumpAndSettle();
      expect(held, isEmpty);
      expect(ayahTint(tester), isNull);
    });

    testWidgets('a scroll that wins first still clears the press (device slop)', (
      tester,
    ) async {
      // Android reports a smaller touch slop than Flutter's default, so the
      // page scroll claims the drag before the long press gives up.
      final held = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              gestureSettings: DeviceGestureSettings(touchSlop: 8),
            ),
            child: Builder(
              builder: (context) => Scaffold(
                body: ScrollConfiguration(
                  behavior: const ScrollBehavior(),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        QuranReadingText(
                          ayahs: ayahs,
                          active: 0,
                          scale: 1,
                          font: arabicFontById('noorehuda'),
                          onHold: (a) => held.add(a.ayahNumber),
                        ),
                        const SizedBox(height: 2000),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final text = tester.getRect(find.byType(RichText).first);
      final press = await tester.startGesture(
        Offset(text.right - 20, text.center.dy),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(ayahTint(tester), isNotNull);
      for (var i = 0; i < 10; i++) {
        await press.moveBy(const Offset(0, -3));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(kAyahHoldDuration);
      expect(ayahTint(tester), isNull);
      await press.up();
      await tester.pumpAndSettle();
      expect(held, isEmpty);
      expect(ayahTint(tester), isNull);
    });

    testWidgets('re-sent ayahs mid-press keep the hold going', (tester) async {
      final held = <int>[];
      Widget reader() => MaterialApp(
        home: Scaffold(
          body: QuranReadingText(
            // A fresh list with the same ayahs, as a reading update sends.
            ayahs: List.of(ayahs),
            active: 0,
            scale: 1,
            font: arabicFontById('noorehuda'),
            onHold: (a) => held.add(a.ayahNumber),
          ),
        ),
      );
      await tester.pumpWidget(reader());
      final text = tester.getRect(find.byType(RichText).first);
      final press = await tester.startGesture(
        Offset(text.right - 20, text.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpWidget(reader());
      await tester.pump(kAyahHoldDuration);
      expect(held, [3]);
      await press.up();
      await tester.pumpAndSettle();
      expect(ayahTint(tester), isNull);
    });

    testWidgets('a small wobble still completes the hold', (tester) async {
      final held = await pump(tester);
      final press = await tester.startGesture(tester.getCenter(marker));
      await tester.pump(const Duration(milliseconds: 200));
      await press.moveBy(const Offset(2, 3));
      await tester.pump(kAyahHoldDuration);
      expect(held, [3]);
      await press.up();
    });
  });
}
