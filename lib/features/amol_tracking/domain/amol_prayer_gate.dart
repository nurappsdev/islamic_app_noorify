import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';

/// Whether an Amol prayer item may be logged at [now].
///
/// The tracker is grouped by the local calendar day (midnight to midnight),
/// and [trackingDate] is the day the tick would be recorded against — the day
/// [now] falls in. Each item opens when its own prayer time begins on that
/// day, which is why Isha and Witr have to be ticked before midnight closes
/// the day.
///
/// Two Nafl items are not tied to a single prayer time:
///
///  * **Tahajjud** is prayed in the night, which straddles midnight, so its
///    window runs from Isha until Fajr begins — see [_canLogTahajjud].
///  * **Salatul Wudu** and **Tahiyyatul Masjid** are prayed whenever their
///    occasion arises (after performing wudu, on entering a masjid), so they
///    are open all day and are not gated at all.
bool canLogAmolPrayerItem({
  required DateTime now,
  required DateTime trackingDate,
  required String pillarKey,
  required String itemKey,
  required DailyPrayerTimes times,
}) {
  if (!_timeGatedPillarKeys.contains(pillarKey)) return true;
  if (itemKey == 'tahajjud') {
    return _canLogTahajjud(now: now, trackingDate: trackingDate, times: times);
  }
  final gate = _gateStart(itemKey, times);
  if (gate == null) return true;
  return !now.isBefore(_at(trackingDate, gate));
}

/// Tahajjud's window: from Isha until Fajr, across midnight.
///
/// [now] always sits inside [trackingDate], so the night Tahajjud belongs to
/// is the one that ends with [trackingDate]'s Fajr. Before that Fajr the
/// window was opened by *last* evening's Isha (the clock has already passed
/// midnight, and the tick is recorded against this new day). Once Fajr
/// begins the night is over and nothing may be logged until this evening's
/// Isha, which opens the window again for the few hours left of the day.
bool _canLogTahajjud({
  required DateTime now,
  required DateTime trackingDate,
  required DailyPrayerTimes times,
}) {
  if (now.isBefore(_at(trackingDate, times.fajr))) {
    return !now.isBefore(_at(trackingDate, times.isha, dayOffset: -1));
  }
  return !now.isBefore(_at(trackingDate, times.isha));
}

/// [time] on [date] (shifted by [dayOffset] whole days), built from the
/// calendar rather than by adding hours so a daylight-saving change can't
/// move it.
DateTime _at(DateTime date, PrayerClockTime time, {int dayOffset = 0}) =>
    DateTime(
      date.year,
      date.month,
      date.day + dayOffset,
      time.hour,
      time.minute,
    );

const _timeGatedPillarKeys = {'fardh_prayer', 'sunnah_witr', 'nafl_salat'};

PrayerClockTime? _gateStart(String itemKey, DailyPrayerTimes times) {
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
      return times.maghrib;
    case 'isha':
    case 'isha_sunnah':
    case 'witr':
      return times.isha;
    case 'ishraq':
    case 'chasht':
      return times.sunrise;
    // Everything else — Salatul Wudu (the API still keys it `awabin`),
    // Tahiyyatul Masjid — has no prayer time of its own and stays open for
    // the whole day.
    default:
      return null;
  }
}
