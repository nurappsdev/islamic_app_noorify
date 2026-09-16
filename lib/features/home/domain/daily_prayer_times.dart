import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

class DailyPrayerTimes {
  const DailyPrayerTimes({
    required this.dateKey,
    required this.readableDate,
    required this.hijriDate,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.sunset,
    required this.isha,
  });

  final String dateKey;
  final String readableDate;
  final String hijriDate;
  final PrayerClockTime fajr;
  final PrayerClockTime sunrise;
  final PrayerClockTime dhuhr;
  final PrayerClockTime asr;
  final PrayerClockTime maghrib;
  final PrayerClockTime sunset;
  final PrayerClockTime isha;

  Map<String, dynamic> toJson() => {
    'dateKey': dateKey,
    'readableDate': readableDate,
    'hijriDate': hijriDate,
    'fajr': fajr.totalMinutes,
    'sunrise': sunrise.totalMinutes,
    'dhuhr': dhuhr.totalMinutes,
    'asr': asr.totalMinutes,
    'maghrib': maghrib.totalMinutes,
    'sunset': sunset.totalMinutes,
    'isha': isha.totalMinutes,
  };

  factory DailyPrayerTimes.fromJson(Map<String, dynamic> json) {
    PrayerClockTime time(String key) {
      final minutes = json[key];
      if (minutes is! int || minutes < 0 || minutes >= 24 * 60) {
        throw const FormatException('Invalid cached prayer time');
      }
      return PrayerClockTime(hour: minutes ~/ 60, minute: minutes % 60);
    }

    final dateKey = json['dateKey'];
    final readableDate = json['readableDate'];
    final hijriDate = json['hijriDate'];
    if (dateKey is! String || readableDate is! String || hijriDate is! String) {
      throw const FormatException('Invalid cached prayer date');
    }
    return DailyPrayerTimes(
      dateKey: dateKey,
      readableDate: readableDate,
      hijriDate: hijriDate,
      fajr: time('fajr'),
      sunrise: time('sunrise'),
      dhuhr: time('dhuhr'),
      asr: time('asr'),
      maghrib: time('maghrib'),
      sunset: time('sunset'),
      isha: time('isha'),
    );
  }
}

String formatPrayerTime(PrayerClockTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

final _clockTimeRegExp = RegExp(
  r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
  caseSensitive: false,
);

/// The inverse of [formatPrayerTime] — parses a 12-hour clock string like
/// `"10:00 AM"` (as returned by `GET /alarms`'s `time`/`alarmTime` fields)
/// into a [PrayerClockTime], or `null` if it doesn't match that shape.
PrayerClockTime? parseClockTime12h(String time) {
  final match = _clockTimeRegExp.firstMatch(time.trim());
  if (match == null) return null;
  final hour12 = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final isPm = match.group(3)!.toUpperCase() == 'PM';
  final hour24 = hour12 % 12 + (isPm ? 12 : 0);
  return PrayerClockTime(hour: hour24, minute: minute);
}

/// Fraction (0..1) of daylight elapsed between [DailyPrayerTimes.sunrise] and
/// [DailyPrayerTimes.sunset] at [now] — 0 at/before sunrise, 1 at/after
/// sunset.
double dayProgress(DateTime now, DailyPrayerTimes times) {
  final sunrise = times.sunrise.totalMinutes;
  final sunset = times.sunset.totalMinutes;
  if (sunset <= sunrise) return 0;
  final nowMinutes = now.hour * 60 + now.minute + now.second / 60;
  return ((nowMinutes - sunrise) / (sunset - sunrise)).clamp(0.0, 1.0);
}

extension PrayerClockTimeShift on PrayerClockTime {
  /// [minutes] may be negative; wraps around midnight.
  PrayerClockTime plusMinutes(int minutes) {
    final wrapped = (totalMinutes + minutes) % (24 * 60);
    final normalized = wrapped < 0 ? wrapped + 24 * 60 : wrapped;
    return PrayerClockTime(hour: normalized ~/ 60, minute: normalized % 60);
  }
}

class ProhibitedPrayerWindow {
  const ProhibitedPrayerWindow({required this.start, required this.end});

  final PrayerClockTime start;
  final PrayerClockTime end;

  String get formatted =>
      '${formatPrayerTime(start)} – ${formatPrayerTime(end)}';
}

/// The three daily windows during which prayer is disliked/prohibited:
/// right after sunrise, around solar zawal (just before Dhuhr), and just
/// before sunset. Durations follow common convention (there is no single
/// fixed figure across schools of thought).
class ProhibitedPrayerWindows {
  const ProhibitedPrayerWindows({
    required this.sunrise,
    required this.zawal,
    required this.sunset,
  });

  factory ProhibitedPrayerWindows.fromDailyTimes(DailyPrayerTimes times) {
    return ProhibitedPrayerWindows(
      sunrise: ProhibitedPrayerWindow(
        start: times.sunrise,
        end: times.sunrise.plusMinutes(15),
      ),
      zawal: ProhibitedPrayerWindow(
        start: times.dhuhr.plusMinutes(-10),
        end: times.dhuhr,
      ),
      sunset: ProhibitedPrayerWindow(
        start: times.sunset.plusMinutes(-15),
        end: times.maghrib,
      ),
    );
  }

  final ProhibitedPrayerWindow sunrise;
  final ProhibitedPrayerWindow zawal;
  final ProhibitedPrayerWindow sunset;
}
