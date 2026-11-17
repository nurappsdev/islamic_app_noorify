/// Bengali (Bangla) calendar date, converted using the fixed-epoch civil
/// calendar Bangladesh adopted in its 2019 reform: Pohela Boishakh always
/// falls on Gregorian 14 April. The first six months have 31 days; Falgun
/// absorbs the leap day instead of the start date shifting year to year.
class BanglaDate {
  const BanglaDate({
    required this.year,
    required this.month,
    required this.day,
  });

  /// Bangla year.
  final int year;

  /// Bangla month, 1 (Boishakh) through 12 (Choitro).
  final int month;

  /// Day of month, 1-based.
  final int day;

  static const monthNames = [
    'বৈশাখ',
    'জ্যৈষ্ঠ',
    'আষাঢ়',
    'শ্রাবণ',
    'ভাদ্র',
    'আশ্বিন',
    'কার্তিক',
    'অগ্রহায়ণ',
    'পৌষ',
    'মাঘ',
    'ফাল্গুন',
    'চৈত্র',
  ];

  static const weekdayShortNames = [
    'রবি', // Sunday
    'সোম',
    'মঙ্গল',
    'বুধ',
    'বৃহঃ',
    'শুক্র',
    'শনি', // Saturday
  ];

  static bool _isGregorianLeap(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  /// Days in Bangla [month] of Bangla [year]. Bangladesh's revised calendar
  /// gives months 1-6 31 days, months 7-10 and 12 30 days, and Falgun (11)
  /// 29 days—30 when the Gregorian February in that Bangla year is a leap
  /// month.
  static int daysInMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month == 11) {
      final gregorianYearOfFalgun = year + 594;
      return _isGregorianLeap(gregorianYearOfFalgun) ? 30 : 29;
    }
    return 30;
  }

  static BanglaDate fromGregorian(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final epochThisYear = DateTime(d.year, 4, 14);
    final int epochGregorianYear;
    final DateTime epoch;
    if (d.isBefore(epochThisYear)) {
      epochGregorianYear = d.year - 1;
      epoch = DateTime(epochGregorianYear, 4, 14);
    } else {
      epochGregorianYear = d.year;
      epoch = epochThisYear;
    }
    final year = epochGregorianYear - 593;
    var daysPassed = d.difference(epoch).inDays;
    var month = 1;
    while (true) {
      final len = daysInMonth(year, month);
      if (daysPassed < len) break;
      daysPassed -= len;
      month++;
    }
    return BanglaDate(year: year, month: month, day: daysPassed + 1);
  }

  /// The Gregorian date for Bangla ([year], [month], [day]).
  static DateTime toGregorian(int year, int month, int day) {
    final epochGregorianYear = year + 593;
    final epoch = DateTime(epochGregorianYear, 4, 14);
    var offset = 0;
    for (var m = 1; m < month; m++) {
      offset += daysInMonth(year, m);
    }
    offset += day - 1;
    return epoch.add(Duration(days: offset));
  }
}
