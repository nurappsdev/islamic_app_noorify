import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/quran/domain/arabic_font.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_ayah.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_reading_text.dart';

/// Al-Baqarah 2:1-7, as the reader shows them.
const _ayahs = [
  'الٓمّٓ',
  'ذٰلِكَ الْكِتٰبُ لَا رَیْبَ فِیْهِ هُدًى لِّلْمُتَّقِیْنَ',
  'الَّذِیْنَ یُؤْمِنُوْنَ بِالْغَیْبِ وَیُقِیْمُوْنَ الصَّلٰوةَ وَمِمَّا رَزَقْنٰهُمْ یُنْفِقُوْنَ',
  'وَالَّذِیْنَ یُؤْمِنُوْنَ بِمَاۤ اُنْزِلَ اِلَیْكَ وَمَاۤ اُنْزِلَ مِنْ قَبْلِكَ وَبِالْاٰخِرَةِ هُمْ یُوْقِنُوْنَ',
  'اُولٰٓىِٕكَ عَلٰى هُدًى مِّنْ رَّبِّهِمْ وَاُولٰٓىِٕكَ هُمُ الْمُفْلِحُوْنَ',
  'اِنَّ الَّذِیْنَ كَفَرُوْا سَوَآءٌ عَلَیْهِمْ ءَاَنْذَرْتَهُمْ اَمْ لَمْ تُنْذِرْهُمْ لَا یُؤْمِنُوْنَ',
  'خَتَمَ اللّٰهُ عَلٰى قُلُوْبِهِمْ وَعَلٰى سَمْعِهِمْ وَعَلٰۤى اَبْصَارِهِمْ غِشَاوَةٌ وَّلَهُمْ عَذَابٌ عَظِیْمٌ',
];

Future<void> _font(String family, String path) =>
    (FontLoader(family)..addFont(
          Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
        ))
        .load();

void main() {
  // The real Quran fonts: the test font's square glyphs make every word
  // wider than any line.
  setUpAll(() async {
    await _font('IndoPak Nastaleeq', 'assets/fonts/quran/IndopakNastaleeq.ttf');
    await _font(
      'AlQalam Quran Majeed',
      'assets/fonts/quran/AlQalamQuranMajeed.otf',
    );
  });

  Future<void> pump(WidgetTester tester, double scale) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 330,
              child: QuranReadingText(
                ayahs: [
                  for (final (i, text) in _ayahs.indexed)
                    QuranAyah(
                      surahNumber: 2,
                      ayahNumber: i + 1,
                      verseKey: '2:${i + 1}',
                      ayahIndex: i + 8,
                      paraNumber: 1,
                      pageNumber: 2,
                      textArabic: text,
                    ),
                ],
                active: 0,
                scale: scale,
                font: arabicFontById(kDefaultArabicFontId),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  /// Each drawn line: where its text starts and ends, and the word spacing
  /// it was given.
  List<({double left, double right, double spacing})> lines(
    WidgetTester tester,
  ) => [
    for (final element
        in find
            .byWidgetPredicate(
              (w) => w is RichText && (w.text as TextSpan).children != null,
            )
            .evaluate())
      () {
        final paragraph = element.renderObject! as RenderParagraph;
        final span = (element.widget as RichText).text as TextSpan;
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: span.toPlainText().length),
        );
        final origin = paragraph.localToGlobal(Offset.zero).dx;
        return (
          left:
              origin + boxes.map((b) => b.left).reduce((a, b) => a < b ? a : b),
          right:
              origin +
              boxes.map((b) => b.right).reduce((a, b) => a > b ? a : b),
          spacing: span.children!
              .whereType<TextSpan>()
              .map((s) => s.style?.wordSpacing ?? 0)
              .fold(0.0, (a, b) => a > b ? a : b),
        );
      }(),
  ];

  for (final scale in [1.2, 2.2]) {
    testWidgets('at ${scale}x every line but the last runs edge to edge', (
      tester,
    ) async {
      await pump(tester, scale);
      final edge = tester.getRect(find.byType(QuranReadingText));
      final drawn = lines(tester);
      expect(drawn.length, greaterThan(3));
      for (final line in drawn) {
        expect(line.left, greaterThanOrEqualTo(edge.left - .5));
        expect(line.right, lessThanOrEqualTo(edge.right + .5));
      }
      for (final line in drawn.take(drawn.length - 1)) {
        // Right to left: each line starts at the right edge and, but for
        // lines of a single word, ends at the left.
        expect(line.right, moreOrLessEquals(edge.right, epsilon: 1));
        if (line.spacing != 0) {
          expect(line.left, moreOrLessEquals(edge.left, epsilon: 1));
        }
      }
      // The last line keeps its natural gaps.
      expect(drawn.last.spacing, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the widening is shared out, not left to one line', (
    tester,
  ) async {
    await pump(tester, 1.2);
    final spacings = [for (final line in lines(tester)) line.spacing]
      ..removeLast();
    final widened = spacings.where((s) => s > 0).length;
    expect(widened, greaterThan(spacings.length ~/ 2));
  });

  testWidgets('resized again at once, it fills its lines once it settles', (
    tester,
  ) async {
    await pump(tester, 1.2);
    await pump(tester, 1.3);
    // Mid-resize: laid out plainly.
    expect(lines(tester), hasLength(1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(lines(tester).length, greaterThan(3));
  });
}
