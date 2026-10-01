import 'package:tuhfatul_muslim/core/localization/localized_date_formatter.dart';
import 'package:tuhfatul_muslim/core/localization/localized_number_formatter.dart';
import 'package:tuhfatul_muslim/core/localization/localized_time_formatter.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

export 'package:tuhfatul_muslim/core/localization/localized_date_formatter.dart'
    show hijriLocalOffsetDays, isAfterMaghrib, localHijriDate;

// Thin wrappers over the shared formatters in `core/localization`, kept so the
// existing `bangla:` / `english:` call sites keep working. New code should use
// LocalizedDateFormatter / LocalizedTimeFormatter / LocalizedNumberFormatter
// with an [AppLanguage] directly.

AppLanguage _language(bool bangla) =>
    bangla ? AppLanguage.bangla : AppLanguage.english;

/// Swaps the ASCII digits in [text] for Bangla ones when [bangla] is true.
String localizeDigits(String text, {required bool bangla}) =>
    LocalizedNumberFormatter(_language(bangla)).digits(text);

/// A clock string like `10:30 AM`, with Bangla digits and পূর্বাহ্ণ/অপরাহ্ণ
/// when [bangla].
String localizeClockText(String text, {required bool bangla}) =>
    LocalizedTimeFormatter(_language(bangla)).localize(text);

/// [date] on the Bengali calendar - Bangla script by default, e.g.
/// `৭ শ্রাবণ ১৪৩৩`, or with [english] Latin script and digits, e.g.
/// `11 Ashwin, 1433`. Computed from [date], so it rolls over on its own.
String banglaDateLabel(DateTime date, {bool english = false}) =>
    LocalizedDateFormatter(_language(!english)).banglaCalendar(date);

/// [date] on the Hijri (Arabic) calendar - e.g. `7 Safar 1444 Hijri`, or with
/// [bangla] `৭ সফর ১৪৪৪ হিজরি`. See [localHijriDate] for how the day is
/// chosen.
String hijriDateLabel(
  DateTime date, {
  bool bangla = false,
  PrayerClockTime? maghrib,
}) => LocalizedDateFormatter(_language(bangla)).hijri(date, maghrib: maghrib);
