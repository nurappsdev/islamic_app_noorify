class PrayerClockTime {
  const PrayerClockTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour <= 23),
      assert(minute >= 0 && minute <= 59);

  final int hour;
  final int minute;

  int get totalMinutes => hour * 60 + minute;
}

const nightPrayerThemeAsset = 'assets/images/theme4.png';

String prayerThemeAsset({
  required DateTime now,
  required PrayerClockTime fajr,
}) {
  final minute = now.hour * 60 + now.minute;
  if (minute < fajr.totalMinutes) return nightPrayerThemeAsset;
  if (minute <= 10 * 60) return 'assets/images/theme1.png';
  if (minute <= 16 * 60) return 'assets/images/theme2.png';
  if (minute <= 19 * 60 + 30) return 'assets/images/theme3.png';
  return nightPrayerThemeAsset;
}

/// Whether the night background ([nightPrayerThemeAsset]) is showing —
/// before Fajr or after the Maghrib/evening window.
bool isNightPrayerTheme({
  required DateTime now,
  required PrayerClockTime fajr,
}) => prayerThemeAsset(now: now, fajr: fajr) == nightPrayerThemeAsset;

DateTime nextPrayerThemeBoundary({
  required DateTime now,
  required PrayerClockTime fajr,
}) {
  DateTime at(int dayOffset, [int hour = 0, int minute = 0]) {
    final day = now.day + dayOffset;
    return now.isUtc
        ? DateTime.utc(now.year, now.month, day, hour, minute)
        : DateTime(now.year, now.month, day, hour, minute);
  }

  final candidates = <DateTime>[
    at(0, fajr.hour, fajr.minute),
    at(0, 10, 1),
    at(0, 16, 1),
    at(0, 19, 31),
    at(1),
    at(1, fajr.hour, fajr.minute),
  ];
  return candidates.firstWhere((candidate) => candidate.isAfter(now));
}
