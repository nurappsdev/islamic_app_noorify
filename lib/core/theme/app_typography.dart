import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

/// The bundled typeface for English text.
const appFontFamily = 'Ubuntu Medium';

/// The bundled typeface for Bangla text.
const appFontFamilyBangla = 'Noto Sans Bengali Regular';

/// Resolves the application typeface from the selected interface language.
String appFontFamilyFor(AppLanguage language) => switch (language) {
  AppLanguage.bangla => appFontFamilyBangla,
  AppLanguage.english => appFontFamily,
};
