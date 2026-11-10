import 'dart:io';

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

  test('uses Hind Siliguri for the Bangla theme', () {
    expect(appFontFamilyBangla, 'Hind Siliguri');

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

  test('registers every Bangla font weight the app can ask for', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('family: $appFontFamilyBangla'));
    for (final weight in const [300, 400, 500, 600, 700]) {
      expect(pubspec, contains('weight: $weight'));
    }
    for (final file in const [
      'HindSiliguri-Light.ttf',
      'HindSiliguri-Regular.ttf',
      'HindSiliguri-Medium.ttf',
      'HindSiliguri-SemiBold.ttf',
      'HindSiliguri-Bold.ttf',
    ]) {
      expect(pubspec, contains(file));
      expect(File('assets/fonts/hind_siliguri/$file').existsSync(), isTrue);
    }
  });

  test('keeps the bundled Quran Arabic font separate from the app font', () {
    final style = arabicFontById(kDefaultArabicFontId).apply(const TextStyle());

    expect(style.fontFamily, 'IndoPak Nastaleeq');
    expect(style.fontFamily, isNot(appFontFamily));
  });
}
