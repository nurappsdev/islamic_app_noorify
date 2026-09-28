import 'package:flutter/widgets.dart';

import 'package:islami_app_noorify/core/localization/localized_number_formatter.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_context.dart';

/// Bilingual content as the API sends it: `{ "bn": "...", "en": "..." }`.
///
/// Either side may be missing or `null` while it waits for translation, so
/// [resolve] falls back to the other language rather than showing nothing.
class LocalizedText {
  const LocalizedText({this.bn, this.en});

  static const LocalizedText empty = LocalizedText();

  final String? bn;
  final String? en;

  /// Reads `{bn, en}`; anything else becomes [empty]. A bare string is taken
  /// as both languages, so an older payload still renders.
  factory LocalizedText.fromJson(Object? json) {
    if (json is Map) {
      return LocalizedText(bn: _clean(json['bn']), en: _clean(json['en']));
    }
    if (json is String) {
      final text = _clean(json);
      return LocalizedText(bn: text, en: text);
    }
    return empty;
  }

  bool get isEmpty => bn == null && en == null;

  /// The text in [language], or the other language when that side is missing.
  String resolve(AppLanguage language) {
    final primary = language == AppLanguage.bangla ? bn : en;
    final secondary = language == AppLanguage.bangla ? en : bn;
    return primary ?? secondary ?? '';
  }

  static String? _clean(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}

/// Writes the ASCII digits of [text] in the script of [language].
String localizeDigits(String text, AppLanguage language) =>
    LocalizedNumberFormatter(language).digits(text);

extension LocalizedTextContext on BuildContext {
  /// [value] in the app's current language; rebuilds when it changes.
  String localized(LocalizedText? value) =>
      value?.resolve(languageOf(this)) ?? '';

  /// [text] with its digits in the app's current language's script.
  String localizedDigits(String text) => localizeDigits(text, languageOf(this));
}

/// Fills the `{name}` placeholders of a localized template:
/// `'Page {n}'.fill({'n': 5})` -> `'Page 5'`. Translations keep their own word
/// order around the placeholders, so a number or name is never glued into a
/// sentence in code.
extension TemplateFill on String {
  String fill(Map<String, Object?> values) {
    var text = this;
    values.forEach((key, value) {
      text = text.replaceAll('{$key}', '$value');
    });
    return text;
  }
}
