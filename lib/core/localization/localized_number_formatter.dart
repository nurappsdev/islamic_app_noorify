import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

/// Writes numbers in the script of the selected language: Bangla digits
/// (০-৯) in Bangla, ordinary digits otherwise.
///
/// This is a presentation-only conversion. Values sent to or received from the
/// backend, and anything parsed or compared in code, stay ordinary numbers;
/// convert only the text that is about to be shown.
class LocalizedNumberFormatter {
  const LocalizedNumberFormatter(this.language);

  final AppLanguage language;

  static const banglaDigits = [
    '০',
    '১',
    '২',
    '৩',
    '৪',
    '৫',
    '৬',
    '৭',
    '৮',
    '৯',
  ];

  bool get isBangla => language == AppLanguage.bangla;

  /// [text] with its digits in this language's script. Anything that isn't an
  /// ASCII digit - letters, punctuation, `:`, `.` - is left as it is.
  String digits(String text) {
    if (!isBangla) return text;
    return text.replaceAllMapped(
      RegExp('[0-9]'),
      (match) => banglaDigits[int.parse(match[0]!)],
    );
  }

  /// A whole number, e.g. `1120` -> `১১২০`.
  String integer(num value) => digits(value.round().toString());

  /// [value] with at most [fractionDigits] decimals and no trailing zeros,
  /// e.g. `72.25` -> `৭২.২৫`, `40.0` -> `৪০`.
  String decimal(num value, {int fractionDigits = 2}) {
    var text = value.toStringAsFixed(fractionDigits);
    if (text.contains('.')) {
      text = text
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }
    return digits(text);
  }
}
