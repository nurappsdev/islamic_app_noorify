class PrayerClockTime {
  const PrayerClockTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour <= 23),
      assert(minute >= 0 && minute <= 59);

  final int hour;
  final int minute;

  int get totalMinutes => hour * 60 + minute;
}

String prayerThemeAsset({
  required DateTime now,
  required PrayerClockTime fajr,
}) {
  final minute = now.hour * 60 + now.minute;
  if (minute < fajr.totalMinutes) return 'assets/images/theme4.png';
  if (minute <= 10 * 60) return 'assets/images/theme1.png';
  if (minute <= 16 * 60) return 'assets/images/theme2.png';
  if (minute <= 19 * 60 + 30) return 'assets/images/theme3.png';
  return 'assets/images/theme4.png';
}

DateTime nextPrayerThemeBoundary({
  required DateTime now,
  required PrayerClockTime fajr,
}) {
  final candidates = <DateTime>[
    DateTime(now.year, now.month, now.day, fajr.hour, fajr.minute),
    DateTime(now.year, now.month, now.day, 10, 1),
    DateTime(now.year, now.month, now.day, 16, 1),
    DateTime(now.year, now.month, now.day, 19, 31),
    DateTime(now.year, now.month, now.day + 1),
    DateTime(now.year, now.month, now.day + 1, fajr.hour, fajr.minute),
  ];
  return candidates.firstWhere((candidate) => candidate.isAfter(now));
}
