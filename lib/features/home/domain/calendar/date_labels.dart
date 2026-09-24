import 'package:hijri/hijri_calendar.dart';

import 'package:islami_app_noorify/features/home/domain/calendar/bangla_date.dart';

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

String _banglaNumber(int value) =>
    '$value'.split('').map((c) => _banglaDigits[int.parse(c)]).join();

/// [date] on the Bengali calendar, in Bangla script - e.g. `৭ শ্রাবণ ১৪৩৩`.
/// Computed from the device date, so it rolls over on its own.
String banglaDateLabel(DateTime date) {
  final bn = BanglaDate.fromGregorian(date);
  return '${_banglaNumber(bn.day)} ${BanglaDate.monthNames[bn.month - 1]} '
      '${_banglaNumber(bn.year)}';
}

/// [date] on the Hijri (Arabic) calendar - e.g. `7 Safar 1444 Hijri`.
/// Computed from the device date.
String hijriDateLabel(DateTime date) {
  final h = HijriCalendar.fromDate(date);
  return '${h.hDay} ${_hijriMonthNamesEn[h.hMonth - 1]} ${h.hYear} Hijri';
}
