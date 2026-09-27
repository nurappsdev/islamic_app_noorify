import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/quran/domain/arabic_font.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_ayah.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_reading_text.dart';

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
                      onTap: (ayah) => tapped = ayah.ayahNumber,
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
        await tester.tap(find.text('٣'));
        expect(tapped, 3);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
