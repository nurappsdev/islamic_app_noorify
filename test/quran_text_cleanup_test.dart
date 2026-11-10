import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_text_cleanup.dart';

// Server samples, written with escapes so the invisible characters show.
void main() {
  test('drops private-use glyphs and keeps the waqf sign on its word', () {
    // 1:7
    expect(
      cleanQuranArabic(
        '\u0639\u0644\u064A\u0647\u0645 \u2060\uE021\u06D9\u200F '
        '\u063A\u064A\u0631',
      ),
      '\u0639\u0644\u064A\u0647\u0645\u06D9 \u063A\u064A\u0631',
    );
  });

  test('turns the hyphen after a waqf sign into a space', () {
    // 2:255
    expect(
      cleanQuranArabic('\u0647\u0648\u06DA-\u0627\u0644\u062D\u064A'),
      '\u0647\u0648\u06DA \u0627\u0644\u062D\u064A',
    );
  });

  test('drops font symbols but keeps lam-alef as letters', () {
    expect(
      cleanQuranArabic(
        '\u0627\u0644\u0642\u064A\u0648\u0645 \u2060\uFCDB \u0644\u0627',
      ),
      '\u0627\u0644\u0642\u064A\u0648\u0645 \u0644\u0627',
    );
    expect(
      cleanQuranArabic('\u0648\u00A0\u0627\uFEFC'),
      '\u0648\u00A0\u0627\u0644\u0627',
    );
  });

  test('drops ruku markers', () {
    // 68:52
    expect(
      cleanQuranArabic(
        '\u0644\u0644\u0639\u0644\u0645\u064A\u0646\u06E0 (52)\u065B',
      ),
      '\u0644\u0644\u0639\u0644\u0645\u064A\u0646',
    );
  });

  test('is idempotent and keeps no-break spaces and sajdah signs', () {
    const clean = '\u0648\u00A0\u0628\u0643\u064A\u0627\u06E9';
    expect(cleanQuranArabic(clean), clean);
  });
}
