/// Bengali (Bangla) calendar date, converted using the fixed-epoch civil
/// calendar Bangladesh adopted in its 2019 reform: Pohela Boishakh always
/// falls on Gregorian 14 April, and Choitro (the last month) absorbs the
/// leap day instead of the start date shifting year to year.
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

  /// Days in Bangla [month] of Bangla [year]. Months 1-5 have 31 days,
  /// 6-11 have 30, and 12 (Choitro) has 31 only when the Gregorian year it
  /// falls in (epoch year + 1) is a leap year.
  static int daysInMonth(int year, int month) {
    if (month == 12) {
      final epochGregorianYear = year + 593;
      return _isGregorianLeap(epochGregorianYear + 1) ? 31 : 30;
    }
    return month <= 5 ? 31 : 30;
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
