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
