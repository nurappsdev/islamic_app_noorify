import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

enum PrayerPeriod { fajr, dhuhr, asr, maghrib, isha }

extension PrayerPeriodLabel on PrayerPeriod {
  String displayName(AppText appText) => switch (this) {
    PrayerPeriod.fajr => appText.prayerFajr,
    PrayerPeriod.dhuhr => appText.prayerDhuhr,
    PrayerPeriod.asr => appText.prayerAsr,
    PrayerPeriod.maghrib => appText.prayerMaghribAndIftar,
    PrayerPeriod.isha => appText.prayerIsha,
  };
}

PrayerPeriod? currentPrayerPeriod(DateTime now, DailyPrayerTimes times) {
  final minute = now.hour * 60 + now.minute;
  if (minute < times.fajr.totalMinutes) return PrayerPeriod.isha;
  if (minute < times.sunrise.totalMinutes) return PrayerPeriod.fajr;
  if (minute < times.dhuhr.totalMinutes) return null;
  if (minute < times.asr.totalMinutes) return PrayerPeriod.dhuhr;
  if (minute < times.maghrib.totalMinutes) return PrayerPeriod.asr;
  if (minute < times.isha.totalMinutes) return PrayerPeriod.maghrib;
  return PrayerPeriod.isha;
}

PrayerClockTime prayerStart(PrayerPeriod period, DailyPrayerTimes times) {
  return switch (period) {
    PrayerPeriod.fajr => times.fajr,
    PrayerPeriod.dhuhr => times.dhuhr,
    PrayerPeriod.asr => times.asr,
    PrayerPeriod.maghrib => times.maghrib,
    PrayerPeriod.isha => times.isha,
  };
}

PrayerClockTime prayerEnd(PrayerPeriod period, DailyPrayerTimes times) {
  return switch (period) {
    PrayerPeriod.fajr => times.sunrise,
    PrayerPeriod.dhuhr => times.asr,
    PrayerPeriod.asr => times.maghrib,
    PrayerPeriod.maghrib => times.isha,
    PrayerPeriod.isha => times.fajr,
  };
}
