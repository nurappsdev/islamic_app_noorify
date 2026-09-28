import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_state.dart';

/// Limits [text] by words, never by character count.
///
/// Whitespace is normalized and an ellipsis is appended only when words were
/// actually omitted. A non-positive [maxWords] produces an empty string.
String truncateWords(String text, int maxWords) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || maxWords <= 0) return '';

  final words = trimmed.split(RegExp(r'\s+'));
  if (words.length <= maxWords) return words.join(' ');
  return '${words.take(maxWords).join(' ')}...';
}

/// Returns the localized, abbreviated month and year for [date], such as
/// `Sep 2026` or `সেপ্ট ২০২৬`.
String localizedShortMonthYear(DateTime date, AppLanguage language) {
  final monthName = AppText.forLanguage(language).monthNames[date.month - 1];
  final month = abbreviateLocalizedMonth(monthName, language);
  final year = language == AppLanguage.bangla
      ? _toBanglaDigits(date.year.toString())
      : date.year.toString();
  return '$month $year';
}

/// Abbreviates a localized month without a list of hard-coded month names.
///
/// English and other Latin labels use their first three characters.
/// Bengali uses the first four code points, extending through a conjunct so
/// a virama is never displayed on its own: `সেপ্টেম্বর` becomes `সেপ্ট`,
/// `জানুয়ারি` becomes `জানু`, and `জুন` remains unchanged.
String abbreviateLocalizedMonth(String monthName, AppLanguage language) {
  final value = monthName.trim();
  if (value.isEmpty) return '';
  if (language != AppLanguage.bangla) {
    return String.fromCharCodes(value.runes.take(3));
  }

  final runes = value.runes.toList();
  const baseLength = 4;
  var length = runes.length < baseLength ? runes.length : baseLength;
  while (length < runes.length && runes[length - 1] == 0x09CD) {
    length++;
  }
  return String.fromCharCodes(runes.take(length));
}

String resolveAmolTrackUserName({String? profileName, String? dashboardName}) {
  final profile = profileName?.trim() ?? '';
  if (profile.isNotEmpty) return profile;
  return dashboardName?.trim() ?? '';
}

String _toBanglaDigits(String value) => value.replaceAllMapped(
  RegExp(r'\d'),
  (match) => const [
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
  ][int.parse(match[0]!)],
);
