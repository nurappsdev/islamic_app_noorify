import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/quran/domain/arabic_font.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_ayah.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_reading_text.dart';

void main() {
  testWidgets('actual font preview', (tester) async {
    final loader = FontLoader('Noorehuda')
      ..addFont(rootBundle.load('assets/fonts/quran/Noorehuda.ttf'));
    await loader.load();
    final key = GlobalKey();
    const texts = [
      'الٓمّٓۚ',
      'ذٰلِكَ الْكِتٰبُ لَا رَیْبَ ﶈ فِیْهِ ۚۛ-هُدًى لِّلْمُتَّقِیْنَۙ',
      'الَّذِیْنَ یُؤْمِنُوْنَ بِالْغَیْبِ وَ یُقِیْمُوْنَ الصَّلٰوةَ وَ مِمَّا رَزَقْنٰهُمْ یُنْفِقُوْنَۙ',
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 320,
                child: ColoredBox(
                  color: Colors.white,
                  child: QuranReadingText(
                    ayahs: [
                      for (var i = 0; i < texts.length; i++)
                        QuranAyah(
                          surahNumber: 2,
                          ayahNumber: i + 1,
                          verseKey: '2:${i + 1}',
                          ayahIndex: i + 8,
                          paraNumber: 1,
                          pageNumber: 2,
                          textArabic: texts[i],
                        ),
                    ],
                    active: 0,
                    scale: 1,
                    font: arabicFontById('noorehuda'),
                    onTap: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    expect(tester.takeException(), isNull);
    const output = String.fromEnvironment('QURAN_PREVIEW_PATH');
    if (output.isEmpty) return;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(output).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
