import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';

/// The Nafl prayers that have a window of their own in the day, in the order
/// they come round: Tahajjud at night, Ishraq just after sunrise, Chasht
/// (Duha) through the late morning, Awwabin between Maghrib and Isha.
enum NaflPeriod { tahajjud, ishraq, chasht, awwabin }

extension NaflPeriodLabel on NaflPeriod {
  /// Chasht is also called Duha, so it carries both names — the one Bengali
  /// speakers use most, with the Arabic name after it.
  String displayName(AppText appText) => switch (this) {
    NaflPeriod.tahajjud => appText.naflTahajjud,
    NaflPeriod.ishraq => appText.naflIshraq,
    NaflPeriod.chasht => '${appText.naflChast} (${appText.naflDuha})',
    NaflPeriod.awwabin => appText.naflAwabin,
  };
}

/// A span of the day between two clock times. [end] may be earlier than
/// [start] on the clock, in which case the window runs across midnight (as
/// Tahajjud's does).
class PrayerTimeWindow {
  const PrayerTimeWindow({required this.start, required this.end});

  final PrayerClockTime start;
  final PrayerClockTime end;

  /// How long the window lasts, counting across midnight when [end] is on the
  /// next day. Two equal ends are an empty window, not a whole day.
  int get spanMinutes {
    final span = end.totalMinutes - start.totalMinutes;
    return span < 0 ? span + minutesPerDay : span;
  }
}

const minutesPerDay = 24 * 60;

/// When [period] may be prayed on the day [times] describes.
///
/// The boundaries follow the convention these prayers are taught with, worked
/// out from the day's own sun times so they move with the season:
///
///  * **Tahajjud** — the last third of the night, from Maghrib to the next
///    Fajr, which is the window `PrayerAlarmBuilder` already schedules the
///    Tahajjud alarm in.
///  * **Ishraq** — from 15 minutes after sunrise, once the sun has risen far
///    enough for the prohibited window to close, until Chasht begins.
///  * **Chasht (Duha)** — from a quarter of the way through the daylight
///    hours until the Zawal window opens just before Dhuhr.
///  * **Awwabin** — after the Maghrib prayer, until Isha begins.
PrayerTimeWindow naflWindow(NaflPeriod period, DailyPrayerTimes times) {
  return switch (period) {
    NaflPeriod.tahajjud => PrayerTimeWindow(
      start: tahajjudStart(times),
      end: times.fajr,
    ),
    NaflPeriod.ishraq => PrayerTimeWindow(
      start: times.sunrise.plusMinutes(15),
      end: _chashtStart(times),
    ),
    NaflPeriod.chasht => PrayerTimeWindow(
      start: _chashtStart(times),
      // The Zawal window, which `ProhibitedPrayerWindows` opens 4 minutes
      // before Dhuhr, closes Chasht.
      end: times.dhuhr.plusMinutes(-4),
    ),
    NaflPeriod.awwabin => PrayerTimeWindow(
      start: times.maghrib,
      end: times.isha,
    ),
  };
}

/// Where the last third of the night begins, counting the night from Maghrib
/// to the next Fajr — the same rule the Tahajjud alarm is built on, so the two
/// screens never disagree about when Tahajjud starts.
PrayerClockTime tahajjudStart(DailyPrayerTimes times) {
  final nightMinutes =
      (minutesPerDay - times.maghrib.totalMinutes) + times.fajr.totalMinutes;
  return times.maghrib.plusMinutes((nightMinutes * 2 / 3).round());
}

/// A quarter of the way through the daylight hours, which is where Ishraq
/// hands over to Chasht.
PrayerClockTime _chashtStart(DailyPrayerTimes times) {
  final daylight = times.sunset.totalMinutes - times.sunrise.totalMinutes;
  if (daylight <= 0) return times.sunrise.plusMinutes(15);
  return times.sunrise.plusMinutes(daylight ~/ 4);
}

/// Whether [now] falls inside [window].
bool isWithinWindow(DateTime now, PrayerTimeWindow window) {
  final elapsed = _minutesSince(now, window.start);
  return elapsed < window.spanMinutes;
}

/// How much of [window] has gone by at [now], as a fraction from 0 (it has
/// just opened) to 1 (it has closed).
double windowProgress(DateTime now, PrayerTimeWindow window) {
  final span = window.spanMinutes;
  if (span <= 0) return 0;
  return (_minutesSince(now, window.start) / span).clamp(0.0, 1.0);
}

/// Whole minutes from [now] until the next [target] on the clock — 0 once
/// [target] is reached, and counted across midnight when it is tomorrow.
int minutesUntilClock(DateTime now, PrayerClockTime target) {
  var remaining = target.totalMinutes - _nowMinutes(now);
  if (remaining < 0) remaining += minutesPerDay;
  return remaining.ceil();
}

/// Minutes from [start] to [now], counted forward across midnight, so a
/// window that opened yesterday evening still reads as elapsed time.
double _minutesSince(DateTime now, PrayerClockTime start) {
  final elapsed = _nowMinutes(now) - start.totalMinutes;
  return elapsed < 0 ? elapsed + minutesPerDay : elapsed;
}

/// [now]'s time of day in minutes, seconds included so a progress bar creeps
/// forward rather than stepping once a minute.
double _nowMinutes(DateTime now) =>
    now.hour * 60 + now.minute + now.second / 60;
