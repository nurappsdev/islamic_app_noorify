import 'package:hijri/hijri_calendar.dart';

import 'package:islami_app_noorify/features/home/domain/calendar/bangla_date.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

const _banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

const _hijriMonthNamesEn = [
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

const _hijriMonthNamesBn = [
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

/// Bengali-calendar month names in Latin script, for the English UI.
const _banglaMonthNamesEn = [
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

String _banglaNumber(int value) => localizeDigits('$value', bangla: true);

/// Swaps the ASCII digits in [text] for Bangla ones when [bangla] is true.
String localizeDigits(String text, {required bool bangla}) {
  if (!bangla) return text;
  return text.replaceAllMapped(
    RegExp(r'\d'),
    (m) => _banglaDigits[int.parse(m[0]!)],
  );
}

/// A clock string like `10:30 AM`, in Bangla digits and AM/PM when [bangla].
String localizeClockText(String text, {required bool bangla}) {
  if (!bangla) return text;
  return localizeDigits(
    text.replaceAll('AM', 'এএম').replaceAll('PM', 'পিএম'),
    bangla: true,
  );
}

/// [date] on the Bengali calendar - Bangla script by default, e.g.
/// `৭ শ্রাবণ ১৪৩৩`, or with [english] Latin script and digits, e.g.
/// `11 Ashwin, 1433`. Computed from [date], so it rolls over on its own.
String banglaDateLabel(DateTime date, {bool english = false}) {
  final bn = BanglaDate.fromGregorian(date);
  if (english) {
    return '${bn.day} ${_banglaMonthNamesEn[bn.month - 1]}, ${bn.year}';
  }
  return '${_banglaNumber(bn.day)} ${BanglaDate.monthNames[bn.month - 1]} '
      '${_banglaNumber(bn.year)}';
}

/// Whether [now] is at or past today's [maghrib]. `false` when Maghrib isn't
/// known yet.
bool isAfterMaghrib(DateTime now, PrayerClockTime? maghrib) =>
    maghrib != null && now.hour * 60 + now.minute >= maghrib.totalMinutes;

/// How many days Bangladesh's Hijri date differs from the Saudi-based one the
/// `hijri` package (Umm al-Qura) and Aladhan follow. Bangladesh sights the
/// moon locally, so its months start a day later; e.g. when those sources say
/// 17 Rabi' al-thani, Bangladesh is on the 16th.
const hijriLocalOffsetDays = -1;

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

/// [date] on the Hijri (Arabic) calendar - e.g. `7 Safar 1444 Hijri`, or with
/// [bangla] `৭ সফর ১৪৪৪ হিজরি`. See [localHijriDate] for how the day is chosen.
String hijriDateLabel(
  DateTime date, {
  bool bangla = false,
  PrayerClockTime? maghrib,
}) {
  final h = localHijriDate(date, maghrib: maghrib);
  if (bangla) {
    return '${_banglaNumber(h.hDay)} ${_hijriMonthNamesBn[h.hMonth - 1]} '
        '${_banglaNumber(h.hYear)} হিজরি';
  }
  return '${h.hDay} ${_hijriMonthNamesEn[h.hMonth - 1]} ${h.hYear} Hijri';
}
