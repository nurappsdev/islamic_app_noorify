import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

/// The bundled typeface for English text.
const appFontFamily = 'Ubuntu Medium';

/// The bundled typeface for Bangla text.
const appFontFamilyBangla = 'Hind Siliguri';

/// The faces every text style falls back to for glyphs its own typeface
/// lacks. [appFontFamily] carries no Bengali glyph at all, so without this
/// Bangla text lands on whatever face the device happens to have - a
/// different weight and width from the rest of the app, blurry at small
/// sizes, and empty boxes on a device with no Bengali font of its own. The
/// same applies to the Arabic Quran faces, which the Quran screens set on
/// whole subtrees, and to Bangla digits.
const appFontFamilyFallback = <String>[
  appFontFamilyBangla,
  'Noto Sans Bengali Regular',
  appFontFamily,
];

/// Resolves the application typeface from the selected interface language.
String appFontFamilyFor(AppLanguage language) => switch (language) {
  AppLanguage.bangla => appFontFamilyBangla,
  AppLanguage.english => appFontFamily,
};
