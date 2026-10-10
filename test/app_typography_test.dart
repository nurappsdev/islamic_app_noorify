import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/theme/app_typography.dart';
import 'package:tuhfatul_muslim/core/theme/dark_theme.dart';
import 'package:tuhfatul_muslim/core/theme/light_theme.dart';
import 'package:tuhfatul_muslim/features/quran/domain/arabic_font.dart';

void main() {
  test('uses Ubuntu Medium as the default app font in both themes', () {
    expect(lightTheme().textTheme.bodyMedium!.fontFamily, appFontFamily);
    expect(darkTheme().textTheme.bodyMedium!.fontFamily, appFontFamily);
    expect(lightTheme().textTheme.titleLarge!.fontFamily, appFontFamily);
    expect(darkTheme().textTheme.titleLarge!.fontFamily, appFontFamily);
  });

  test('uses Noto Sans Bengali Regular for the Bangla theme', () {
    expect(
      lightTheme(
        fontFamily: appFontFamilyBangla,
      ).textTheme.bodyMedium!.fontFamily,
      appFontFamilyBangla,
    );
    expect(
      darkTheme(
        fontFamily: appFontFamilyBangla,
      ).textTheme.titleLarge!.fontFamily,
      appFontFamilyBangla,
    );
  });

  test('keeps the bundled Quran Arabic font separate from the app font', () {
    final style = arabicFontById(kDefaultArabicFontId).apply(const TextStyle());

    expect(style.fontFamily, 'Noorehuda');
    expect(style.fontFamily, isNot(appFontFamily));
  });
}
