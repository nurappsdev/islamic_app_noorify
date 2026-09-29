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
}
