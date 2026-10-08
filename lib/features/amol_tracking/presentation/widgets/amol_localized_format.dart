import 'package:tuhfatul_muslim/core/localization/localized_number_formatter.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

String _pointValue(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

/// Format the API's numeric totals with the selected language's label and digits.
String formatAmolPoints(
  num earned,
  num possible,
  AppText appText,
  AppLanguage language,
) {
  final numbers = LocalizedNumberFormatter(language);
  return '${appText.point} : ${numbers.digits(_pointValue(earned))}/${numbers.digits(_pointValue(possible))}';
}

/// Use the server's resolved dates, with local month names and digits.
String formatAmolRange(
  String startIso,
  String endIso,
  AppText appText,
  AppLanguage language,
) {
  final start = DateTime.tryParse(startIso);
  final end = DateTime.tryParse(endIso);
  if (start == null || end == null) return '';
  final numbers = LocalizedNumberFormatter(language);
  String date(DateTime value) =>
      '${numbers.integer(value.day)} ${appText.monthNames[value.month - 1]} ${numbers.integer(value.year)}';
  return start.year == end.year &&
          start.month == end.month &&
          start.day == end.day
      ? date(start)
      : '${date(start)} - ${date(end)}';
}
