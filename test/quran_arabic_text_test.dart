import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_arabic_text.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_ayah.dart';

void main() {
  test('removes the ﭤ mark from ayah ends and elsewhere', () {
    expect(cleanQuranArabic('مٰلِكِ یَوْمِ الدِّیْنِﭤ'), 'مٰلِكِ یَوْمِ الدِّیْنِ');
    expect(cleanQuranArabic('یُوْقِنُوْنَ ﭤ '), 'یُوْقِنُوْنَ');
    expect(cleanQuranArabic('ا ﭤ ب'), 'ا  ب');
    // Other text is left exactly as it was.
    const plain = 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِیْمِ ';
    expect(cleanQuranArabic(plain), plain);
  });

  test('ayahs from the API come without it', () {
    final ayah = QuranAyah.fromJson({
      'surahNumber': 1,
      'ayahNumber': 4,
      'verseKey': '1:4',
      'ayahIndex': 4,
      'paraNumber': 1,
      'pageNumber': 1,
      'textArabic': 'مٰلِكِ یَوْمِ الدِّیْنِﭤ',
    });
    expect(ayah.textArabic, isNot(contains('ﭤ')));
    expect(ayah.textArabic, 'مٰلِكِ یَوْمِ الدِّیْنِ');
  });
}
