import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/home/domain/current_prayer.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

void main() {
  const times = DailyPrayerTimes(
    dateKey: '2026-08-20',
    readableDate: '20 Aug 2026',
    hijriDate: '7 Safar 1448 Hijri',
    fajr: PrayerClockTime(hour: 4, minute: 23),
    sunrise: PrayerClockTime(hour: 5, minute: 40),
    dhuhr: PrayerClockTime(hour: 12, minute: 8),
    asr: PrayerClockTime(hour: 16, minute: 32),
    maghrib: PrayerClockTime(hour: 18, minute: 35),
    sunset: PrayerClockTime(hour: 18, minute: 35),
    isha: PrayerClockTime(hour: 19, minute: 55),
  );

  test('resolves every prayer interval and the daytime gap', () {
    expect(
      currentPrayerPeriod(DateTime(2026, 8, 20, 4, 23), times),
      PrayerPeriod.fajr,
    );
    expect(currentPrayerPeriod(DateTime(2026, 8, 20, 6), times), isNull);
    expect(
      currentPrayerPeriod(DateTime(2026, 8, 20, 12, 8), times),
      PrayerPeriod.dhuhr,
    );
    expect(
      currentPrayerPeriod(DateTime(2026, 8, 20, 16, 32), times),
      PrayerPeriod.asr,
    );
    expect(
      currentPrayerPeriod(DateTime(2026, 8, 20, 18, 35), times),
      PrayerPeriod.maghrib,
    );
    expect(
      currentPrayerPeriod(DateTime(2026, 8, 20, 19, 55), times),
      PrayerPeriod.isha,
    );
    expect(
      currentPrayerPeriod(DateTime(2026, 8, 20, 2), times),
      PrayerPeriod.isha,
    );
  });

  test('returns exact starts and ends for prayer summaries', () {
    expect(prayerStart(PrayerPeriod.asr, times), times.asr);
    expect(prayerEnd(PrayerPeriod.asr, times), times.maghrib);
    expect(prayerEnd(PrayerPeriod.isha, times), times.fajr);
  });
}
