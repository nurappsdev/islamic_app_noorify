import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/quran/domain/arabic_font.dart';
import 'package:tuhfatul_muslim/features/quran/domain/ayah_end_sign.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_ayah.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_reading_text.dart';

void main() {
  group('splitAyahEndSign', () {
    test('takes the pause sign off the last letter', () {
      // 2:2 ends in لا (U+06D9).
      final end = splitAyahEndSign('هُدًى لِّلْمُتَّقِیْنَۙ');
      expect(end.text, 'هُدًى لِّلْمُتَّقِیْنَ');
      expect(end.sign, 'ۙ');
    });

    test('keeps a run of signs together, the ruku sign too', () {
      expect(splitAyahEndSign('سِنِیْنَؕ۠').sign, 'ؕ۠');
      expect(splitAyahEndSign('رَیْبَۚۛ').sign, 'ۚۛ');
    });

    test('keeps the ornaments after the last word in the text', () {
      // 2:8: a م sign, then the font's وقف لازم glyph.
      final end = splitAyahEndSign('بِمُؤْمِنِیْنَۘ ');
      expect(end.text, 'بِمُؤْمِنِیْنَ ');
      expect(end.sign, 'ۘ');
    });

    test('an ayah without one is left alone', () {
      final end = splitAyahEndSign('اُولٰٓئِكَ هُمُ الْمُفْلِحُوْنَ');
      expect(end.text, 'اُولٰٓئِكَ هُمُ الْمُفْلِحُوْنَ');
      expect(end.sign, isEmpty);
    });

    test('signs inside an ayah stay where they are', () {
      expect(splitAyahEndSign('رَیْبَۚۛ فِیْهِ').sign, isEmpty);
    });
  });

  testWidgets('the sign is drawn on the marker, not the last word', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranReadingText(
            ayahs: const [
              QuranAyah(
                surahNumber: 2,
                ayahNumber: 2,
                verseKey: '2:2',
                ayahIndex: 9,
                paraNumber: 1,
                pageNumber: 2,
                textArabic: 'هُدًى لِّلْمُتَّقِیْنَۙ',
              ),
              QuranAyah(
                surahNumber: 2,
                ayahNumber: 5,
                verseKey: '2:5',
                ayahIndex: 12,
                paraNumber: 1,
                pageNumber: 2,
                textArabic: 'هُمُ الْمُفْلِحُوْنَ',
              ),
            ],
            active: 0,
            scale: 1,
            font: arabicFontById(kDefaultArabicFontId),
          ),
        ),
      ),
    );
    // The reader's paragraph (a RichText subclass) holds the Arabic.
    final text = tester
        .widgetList<RichText>(
          find.byWidgetPredicate((w) => w is RichText && w.text is TextSpan),
        )
        .map((w) => w.text.toPlainText())
        .firstWhere((t) => t.contains('هُدًى'));
    expect(text, isNot(contains('ۙ')));
    expect(text, contains('لِّلْمُتَّقِیْنَ'));

    final signs = find.byKey(const ValueKey('ayah-end-sign'));
    expect(signs, findsOneWidget, reason: 'only 2:2 ends with a sign');
    expect(tester.widget<Text>(signs).data, ' ۙ');
    expect(
      find.ancestor(
        of: signs,
        matching: find.byKey(const ValueKey('ayah-marker-2:2')),
      ),
      findsOneWidget,
    );
  });
}
