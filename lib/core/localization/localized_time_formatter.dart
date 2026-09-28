import 'package:islami_app_noorify/core/localization/localized_number_formatter.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_state.dart';

/// Clock times in the selected language: digits in that language's script and
/// its own AM/PM (Bangla: পূর্বাহ্ণ / অপরাহ্ণ).
///
/// Every screen shows a time through this class, so they all agree. The
/// underlying values (and `formatPrayerTime`, which the alarm scheduler uses in
/// a background isolate with no language) stay in English.
class LocalizedTimeFormatter {
  const LocalizedTimeFormatter(this.language);

  final AppLanguage language;

  LocalizedNumberFormatter get _numbers => LocalizedNumberFormatter(language);
  AppText get _text => AppText.forLanguage(language);

  /// Shown where a time isn't known yet.
  static const placeholder = '--:--';

  /// `5:56 PM` -> `৫:৫৬ অপরাহ্ণ` in Bangla.
  String clock(PrayerClockTime time) => localize(formatPrayerTime(time));

  /// The time of day of [dateTime].
  String clockOf(DateTime dateTime) =>
      clock(PrayerClockTime(hour: dateTime.hour, minute: dateTime.minute));

  /// [clock], or [placeholder] when [time] is null.
  String clockOrPlaceholder(PrayerClockTime? time) =>
      time == null ? placeholder : clock(time);

  /// `start – end`, each end localized.
  String range(PrayerClockTime start, PrayerClockTime end) =>
      '${clock(start)} – ${clock(end)}';

  /// A time string that is already formatted in English (`4:10 AM`, as
  /// `formatPrayerTime` writes it, or a `4:10 AM - 5:20 AM` range) written in
  /// this language. Text without a time in it is returned unchanged.
  String localize(String text) {
    if (language != AppLanguage.bangla) return text;
    final withMeridiem = text.replaceAllMapped(
      RegExp(r'\b(AM|PM)\b', caseSensitive: false),
      (match) =>
          match[1]!.toUpperCase() == 'AM' ? _text.amLabel : _text.pmLabel,
    );
    return _numbers.digits(withMeridiem);
  }

  /// `2 hr 5 min` / `২ ঘণ্টা ৫ মিনিট`.
  String duration({required int hours, required int minutes}) =>
      '${_numbers.integer(hours)} ${_text.hrLabel} '
      '${_numbers.integer(minutes)} ${_text.minLabel}';
}
