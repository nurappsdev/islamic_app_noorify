import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/localization/localized_number_formatter.dart';

import 'language_state.dart';

/// The app language the user picked, kept in SharedPreferences so it survives a
/// restart.
///
/// Bangla is the default: with nothing saved (a first launch, guest or signed
/// in) or an unreadable value, the app opens in Bangla. The device's own
/// language is never consulted.
class LanguagePreference {
  const LanguagePreference._();

  static const key = 'app_language';
  static const defaultLanguage = AppLanguage.bangla;

  /// The language selected right now. [LanguageBloc] keeps it up to date, for
  /// code that has no `BuildContext` - such as the text of a failure - to write
  /// its message in the right language.
  static AppLanguage current = defaultLanguage;

  /// A number formatter for [current].
  static LocalizedNumberFormatter get numbers =>
      LocalizedNumberFormatter(current);

  static const _english = 'en';
  static const _bangla = 'bn';

  /// The saved language, or [defaultLanguage] when there is none.
  static AppLanguage read(SharedPreferences prefs) {
    return switch (prefs.getString(key)) {
      _english => AppLanguage.english,
      _bangla => AppLanguage.bangla,
      _ => defaultLanguage,
    };
  }

  static Future<void> save(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      language == AppLanguage.english ? _english : _bangla,
    );
  }
}
