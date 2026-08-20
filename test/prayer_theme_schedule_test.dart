import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

void main() {
  const fajr = PrayerClockTime(hour: 4, minute: 35);

  test('selects prayer card themes at every requested boundary', () {
    final cases = <(DateTime, String)>[
      (DateTime(2026, 8, 20, 4, 34), 'assets/images/theme4.png'),
      (DateTime(2026, 8, 20, 4, 35), 'assets/images/theme1.png'),
      (DateTime(2026, 8, 20, 10, 0, 59), 'assets/images/theme1.png'),
      (DateTime(2026, 8, 20, 10, 1), 'assets/images/theme2.png'),
      (DateTime(2026, 8, 20, 16, 0, 59), 'assets/images/theme2.png'),
      (DateTime(2026, 8, 20, 16, 1), 'assets/images/theme3.png'),
      (DateTime(2026, 8, 20, 19, 30, 59), 'assets/images/theme3.png'),
      (DateTime(2026, 8, 20, 19, 31), 'assets/images/theme4.png'),
    ];

    for (final (now, expected) in cases) {
      expect(prayerThemeAsset(now: now, fajr: fajr), expected);
    }
  });

  test('returns the next exact card update boundary', () {
    expect(
      nextPrayerThemeBoundary(now: DateTime(2026, 8, 20, 9, 45), fajr: fajr),
      DateTime(2026, 8, 20, 10, 1),
    );
    expect(
      nextPrayerThemeBoundary(now: DateTime(2026, 8, 20, 20), fajr: fajr),
      DateTime(2026, 8, 21),
    );
  });

  test('preserves UTC clock basis when calculating a boundary', () {
    final now = DateTime.utc(2026, 8, 20, 9, 45);

    final boundary = nextPrayerThemeBoundary(now: now, fajr: fajr);

    expect(boundary, DateTime.utc(2026, 8, 20, 10, 1));
    expect(boundary.difference(now), const Duration(minutes: 16));
  });
}
