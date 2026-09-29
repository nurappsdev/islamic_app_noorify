import 'package:hijri/hijri_calendar.dart';

import 'package:tuhfatul_muslim/core/localization/localized_number_formatter.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/home/domain/calendar/bangla_date.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

/// Dates in the selected language: the Gregorian, Hijri and Bengali calendars,
/// with month and weekday names, digits and suffixes all in that language.
///
/// The date each calendar shows comes from the same calculations as before -
/// this class only writes it out. The Hijri calendar follows the local moon
/// sighting and turns over at Maghrib (see [localHijriDate]).
class LocalizedDateFormatter {
  const LocalizedDateFormatter(this.language);

  final AppLanguage language;

  LocalizedNumberFormatter get _numbers => LocalizedNumberFormatter(language);
  AppText get _text => AppText.forLanguage(language);
  bool get _bangla => language == AppLanguage.bangla;

  // --- Names -----------------------------------------------------------------

  static const hijriMonthNamesEn = [
    'Muharram',
    'Safar',
    "Rabi' al-awwal",
    "Rabi' al-thani",
    'Jumada al-awwal',
    'Jumada al-thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  static const hijriMonthNamesBn = [
    'মুহাররম',
    'সফর',
    'রবিউল আউয়াল',
    'রবিউস সানি',
    'জমাদিউল আউয়াল',
    'জমাদিউস সানি',
    'রজব',
    'শাবান',
    'রমজান',
    'শাওয়াল',
    'জিলকদ',
    'জিলহজ',
  ];

  /// The Bengali-calendar month names in Latin script, for the English UI.
  static const banglaMonthNamesEn = [
    'Boishakh',
    'Joishtho',
    'Asharh',
    'Srabon',
    'Bhadro',
    'Ashwin',
    'Kartik',
    'Ogrohayon',
    'Poush',
    'Magh',
    'Falgun',
    'Choitro',
  ];

  /// The weekday name of [date] (Monday is `DateTime.monday`).
  String weekdayName(DateTime date) => _text.weekdayNames[date.weekday - 1];

  /// The short weekday name (`Sat` / `শনি`) for a weekday index counted from
  /// Sunday (0 = Sunday .. 6 = Saturday).
  String weekdayShort(int sundayFirstIndex) {
    if (_bangla) return BanglaDate.weekdayShortNames[sundayFirstIndex];
    final monday = _text.weekdayNames[(sundayFirstIndex + 6) % 7];
    return monday.substring(0, 3);
  }

  /// The Gregorian month name.
  String monthName(int month) => _text.monthNames[month - 1];

  String hijriMonthName(int month) =>
      (_bangla ? hijriMonthNamesBn : hijriMonthNamesEn)[month - 1];

  String banglaMonthName(int month) => _bangla
      ? BanglaDate.monthNames[month - 1]
      : banglaMonthNamesEn[month - 1];

  // --- Dates -----------------------------------------------------------------

  /// `28 September 2026` / `২৮ সেপ্টেম্বর ২০২৬`; with [withWeekday] a weekday
  /// leads: `Monday, 28 September 2026`. [shortMonth] abbreviates an English
  /// month to three letters (`28 Sep 2026`); Bangla always writes it in full.
  String gregorian(
    DateTime date, {
    bool withWeekday = false,
    bool shortMonth = false,
  }) {
    var month = monthName(date.month);
    if (shortMonth && !_bangla) month = month.substring(0, 3);
    final text =
        '${_numbers.integer(date.day)} $month ${_numbers.integer(date.year)}';
    return withWeekday ? '${weekdayName(date)}, $text' : text;
  }

  /// The Hijri date of [now], e.g. `17 Rabi' al-thani 1448 Hijri` /
  /// `১৭ রবিউস সানি ১৪৪৮ হিজরি` (or without the suffix).
  ///
  /// The day changes at [maghrib], not at midnight; without it the calendar
  /// day's date is shown. See [localHijriDate].
  String hijri(
    DateTime now, {
    PrayerClockTime? maghrib,
    bool withSuffix = true,
  }) {
    final h = localHijriDate(now, maghrib: maghrib);
    final text =
        '${_numbers.integer(h.hDay)} ${hijriMonthName(h.hMonth)} '
        '${_numbers.integer(h.hYear)}';
    return withSuffix ? '$text ${_text.hijriSuffix}' : text;
  }

  /// The Bengali-calendar date, e.g. `13 Ashwin, 1433` / `১৩ আশ্বিন ১৪৩৩`.
  String banglaCalendar(DateTime date) {
    final bn = BanglaDate.fromGregorian(date);
    if (_bangla) {
      return '${_numbers.integer(bn.day)} ${banglaMonthName(bn.month)} '
          '${_numbers.integer(bn.year)}';
    }
    return '${bn.day} ${banglaMonthName(bn.month)}, ${bn.year}';
  }
}

/// How many days Bangladesh's Hijri date differs from the Saudi-based one the
/// `hijri` package (Umm al-Qura) and Aladhan follow. Bangladesh sights the
/// moon locally, so its months start a day later; e.g. when those sources say
/// 17 Rabi' al-thani, Bangladesh is on the 16th.
const hijriLocalOffsetDays = -1;

/// Whether [now] is at or past today's [maghrib]. `false` when Maghrib isn't
/// known yet.
bool isAfterMaghrib(DateTime now, PrayerClockTime? maghrib) =>
    maghrib != null && now.hour * 60 + now.minute >= maghrib.totalMinutes;

/// The Hijri date to show at [now] (Bangladesh time).
///
/// A Hijri day begins at Maghrib, not midnight. The base is the local Hijri
/// date of [now]'s calendar day; from today's [maghrib] on it moves to the
/// next Hijri day, and stays there until the next Maghrib. Midnight needs no
/// extra step: the base itself turns over then, and it is still before that
/// day's Maghrib, so the date is not advanced a second time. Without
/// [maghrib] the base date is returned as-is.
HijriCalendar localHijriDate(DateTime now, {PrayerClockTime? maghrib}) {
  final shift = hijriLocalOffsetDays + (isAfterMaghrib(now, maghrib) ? 1 : 0);
  return HijriCalendar.fromDate(now.add(Duration(days: shift)));
}
