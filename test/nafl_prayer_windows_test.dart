import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/nafl_prayer.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';

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

  ({int hour, int minute}) hm(PrayerClockTime time) =>
      (hour: time.hour, minute: time.minute);

  test('each Nafl window is worked out from the day\'s own sun times', () {
    // Tahajjud: the last third of the night counted from Maghrib — the same
    // rule the Tahajjud alarm uses — up to Fajr.
    final tahajjud = naflWindow(NaflPeriod.tahajjud, times);
    expect(hm(tahajjud.start), (hour: 1, minute: 7));
    expect(hm(tahajjud.end), (hour: 4, minute: 23));

    // Ishraq: 15 minutes after sunrise, until Chasht takes over a quarter of
    // the way through the daylight hours.
    final ishraq = naflWindow(NaflPeriod.ishraq, times);
    expect(hm(ishraq.start), (hour: 5, minute: 55));
    expect(hm(ishraq.end), (hour: 8, minute: 53));

    // Chasht (Duha): from there until the Zawal window opens before Dhuhr.
    final chasht = naflWindow(NaflPeriod.chasht, times);
    expect(hm(chasht.start), (hour: 8, minute: 53));
    expect(hm(chasht.end), (hour: 12, minute: 4));

    // Awwabin: between Maghrib and Isha.
    final awwabin = naflWindow(NaflPeriod.awwabin, times);
    expect(hm(awwabin.start), (hour: 18, minute: 35));
    expect(hm(awwabin.end), (hour: 19, minute: 55));
  });

  test('a window that runs past midnight measures its own length', () {
    expect(naflWindow(NaflPeriod.tahajjud, times).spanMinutes, 196);
    expect(naflWindow(NaflPeriod.awwabin, times).spanMinutes, 80);
  });

  test('Tahajjud is only current between its start and Fajr', () {
    final tahajjud = naflWindow(NaflPeriod.tahajjud, times);
    expect(isWithinWindow(DateTime(2026, 8, 20, 23), tahajjud), isFalse);
    expect(isWithinWindow(DateTime(2026, 8, 21, 1, 30), tahajjud), isTrue);
    expect(isWithinWindow(DateTime(2026, 8, 21, 4, 23), tahajjud), isFalse);
  });

  test('progress runs 0 to 1 across the window, midnight included', () {
    final dhuhr = PrayerTimeWindow(start: times.dhuhr, end: times.asr);
    expect(windowProgress(DateTime(2026, 8, 20, 12, 8), dhuhr), 0);
    expect(
      windowProgress(DateTime(2026, 8, 20, 14, 20), dhuhr),
      closeTo(0.5, 0.01),
    );
    expect(windowProgress(DateTime(2026, 8, 20, 16, 32), dhuhr), 1);

    final isha = PrayerTimeWindow(start: times.isha, end: times.fajr);
    expect(
      windowProgress(DateTime(2026, 8, 21, 0, 9), isha),
      closeTo(0.5, 0.01),
    );
  });

  test('prayer is prohibited only inside the three windows', () {
    // Sunrise 5:40 -> 5:55, Zawal 12:04 -> 12:10, sunset 18:20 -> 18:35.
    expect(isProhibitedPrayerTime(DateTime(2026, 8, 20, 5, 40), times), isTrue);
    expect(
      isProhibitedPrayerTime(DateTime(2026, 8, 20, 5, 55), times),
      isFalse,
    );
    expect(isProhibitedPrayerTime(DateTime(2026, 8, 20, 12, 6), times), isTrue);
    expect(
      isProhibitedPrayerTime(DateTime(2026, 8, 20, 12, 10), times),
      isFalse,
    );
    expect(
      isProhibitedPrayerTime(DateTime(2026, 8, 20, 18, 25), times),
      isTrue,
    );
    expect(isProhibitedPrayerTime(DateTime(2026, 8, 20, 13), times), isFalse);
  });

  test('the countdown counts whole minutes, wrapping past midnight', () {
    expect(minutesUntilClock(DateTime(2026, 8, 20, 13), times.asr), 212);
    expect(minutesUntilClock(DateTime(2026, 8, 20, 23), times.fajr), 323);
    expect(minutesUntilClock(DateTime(2026, 8, 20, 12, 8), times.dhuhr), 0);
    // Part of a minute still reads as a minute left, not as nothing left.
    expect(minutesUntilClock(DateTime(2026, 8, 20, 12, 7, 30), times.dhuhr), 1);
  });
}
