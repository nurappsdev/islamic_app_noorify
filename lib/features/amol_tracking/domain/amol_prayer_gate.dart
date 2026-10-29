import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';

/// Whether an Amol prayer item may be logged at [now].
///
/// The tracker is grouped by the local calendar day (midnight to midnight).
/// Tahajjud is prayed in the small hours of its own day, so its gate begins
/// at the *preceding* evening's Isha; every other prayer is gated by its own
/// time on the day being tracked, which is why Isha and Witr have to be
/// ticked before midnight closes that day.
bool canLogAmolPrayerItem({
  required DateTime now,
  required DateTime trackingDate,
  required String pillarKey,
  required String itemKey,
  required DailyPrayerTimes times,
}) {
  final gate = _gateStart(pillarKey, itemKey, times);
  if (gate == null) return true;

  final isPostMidnightTahajjud =
      itemKey == 'tahajjud' &&
      _minutesSinceMidnight(now) < times.fajr.totalMinutes;
  final gateDate = isPostMidnightTahajjud
      ? DateTime(now.year, now.month, now.day - 1, gate.hour, gate.minute)
      : DateTime(
          trackingDate.year,
          trackingDate.month,
          trackingDate.day,
          gate.hour,
          gate.minute,
        );
  return !now.isBefore(gateDate);
}

const _timeGatedPillarKeys = {'fardh_prayer', 'sunnah_witr', 'nafl_salat'};

PrayerClockTime? _gateStart(
  String pillarKey,
  String itemKey,
  DailyPrayerTimes times,
) {
  if (!_timeGatedPillarKeys.contains(pillarKey)) return null;
  switch (itemKey) {
    case 'fajr':
    case 'fajr_sunnah':
      return times.fajr;
    case 'dhuhr':
    case 'dhuhr_sunnah':
      return times.dhuhr;
    case 'asr':
    case 'asr_sunnah':
      return times.asr;
    case 'maghrib':
    case 'maghrib_sunnah':
    case 'awabin':
      return times.maghrib;
    case 'isha':
    case 'isha_sunnah':
    case 'witr':
    case 'tahajjud':
      return times.isha;
    case 'ishraq':
    case 'chasht':
      return times.sunrise;
    default:
      return null;
  }
}

int _minutesSinceMidnight(DateTime time) => time.hour * 60 + time.minute;
