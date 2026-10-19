import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_bundle.dart';
import '../tool/build_quran_arabic_asset.dart';

// Real quran.com endings, with escapes so the marks and glyphs show.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled text has every ayah, without number circles', () async {
    final source = QuranBundle();
    var total = 0;
    for (var n = 1; n <= 114; n++) {
      final surah = await source.surah(n);
      expect(surah.keys.first, '$n:1');
      for (final text in surah.values) {
        expect(text.trim(), isNotEmpty);
        // The number circles; the same range also holds glyphs used
        // within the text.
        expect(text.runes.last, isNot(inInclusiveRange(0xF500, 0xF63F)));
      }
      total += surah.length;
    }
    expect(total, 6236);
    expect((await source.surah(2)).length, 286);
    expect(await source.surah(115), isEmpty);
  });

  test('drops the number circle and keeps the waqf sign on the last word', () {
    // 1:2
    expect(
      withoutAyahNumber('\u0645\u06CC\u0652\u0646\u064E \u06DF\u06D9\uF500'),
      '\u0645\u06CC\u0652\u0646\u064E\u06D9',
    );
  });

  test('keeps a private-use waqf glyph as its own word', () {
    // 2:8
    expect(
      withoutAyahNumber('\u0646\u064E \u06DF\u06D8\uF652\uF507'),
      '\u0646\u064E\u06D8 \uF652',
    );
  });

  test('handles a sign before the carrier and a missing number', () {
    // 4:150
    expect(
      withoutAyahNumber('\u0644\u064B\u0627 \u06D9\u06DF\uF595'),
      '\u0644\u064B\u0627\u06D9',
    );
    // 22:77
    expect(
      withoutAyahNumber('\u0646\u064E \uF693\u06DF'),
      '\u0646\u064E \uF693',
    );
  });

  test('leaves text without an ayah end alone', () {
    expect(
      withoutAyahNumber('\u0628\u0650\u0633\u0652\u0645\u0650'),
      '\u0628\u0650\u0633\u0652\u0645\u0650',
    );
  });
}
