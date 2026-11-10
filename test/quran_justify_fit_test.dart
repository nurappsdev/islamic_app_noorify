import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/quran/domain/arabic_font.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_ayah.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_reading_text.dart';

QuranAyah _ayah(int n, String text) => QuranAyah(
  surahNumber: 2,
  ayahNumber: n,
  verseKey: '2:$n',
  ayahIndex: n + 7,
  paraNumber: 1,
  pageNumber: 2,
  textArabic: text,
);

final _page = [
  _ayah(2, 'ذٰلِكَ الْكِتٰبُ لَا رَیْبَ فِیْهِ هُدًى لِّلْمُتَّقِیْنَ'),
  _ayah(
    3,
    'الَّذِیْنَ یُؤْمِنُوْنَ بِالْغَیْبِ وَیُقِیْمُوْنَ الصَّلٰوةَ وَمِمَّا رَزَقْنٰهُمْ یُنْفِقُوْنَ',
  ),
  _ayah(
    5,
    'اُولٰٓىِٕكَ عَلٰى هُدًى مِّنْ رَّبِّهِمْ وَاُولٰٓىِٕكَ هُمُ الْمُفْلِحُوْنَ',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The real font: the test font's square glyphs make every word huge.
  setUpAll(
    () =>
        (FontLoader('IndoPak Nastaleeq')..addFont(
              Future.value(
                ByteData.sublistView(
                  File(
                    'assets/fonts/quran/IndopakNastaleeq.ttf',
                  ).readAsBytesSync(),
                ),
              ),
            ))
            .load(),
  );

  double fit(List<QuranAyah> ayahs, double scale, double width) =>
      quranJustifyFit(
        ayahs: ayahs,
        scale: scale,
        font: arabicFontById(kDefaultArabicFontId),
        textScaler: TextScaler.noScaling,
        width: width,
      );

  test('a passage on one line has nothing to justify', () {
    expect(fit([_ayah(1, 'الٓمّٓ')], 1.2, 330), 0);
  });

  test('lines of only a few words fit worse than full ones', () {
    final normal = fit(_page, 1.2, 330);
    final zoomed = fit(_page, 2.5, 330);
    expect(normal, greaterThanOrEqualTo(0));
    expect(zoomed, greaterThan(normal));
  });

  test('the fit differs from size to size, so a zoom can pick one', () {
    final scores = {
      for (final scale in [1.4, 1.425, 1.45, 1.475, 1.5])
        fit(_page, scale, 330).toStringAsFixed(3),
    };
    expect(scores.length, greaterThan(1));
  });
}
