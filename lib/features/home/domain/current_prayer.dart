import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/home/domain/calendar/date_labels.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';

enum PrayerPeriod { fajr, dhuhr, asr, maghrib, isha }

extension PrayerPeriodLabel on PrayerPeriod {
  String displayName(AppText appText) => switch (this) {
    PrayerPeriod.fajr => appText.prayerFajr,
    PrayerPeriod.dhuhr => appText.prayerDhuhr,
    PrayerPeriod.asr => appText.prayerAsr,
    PrayerPeriod.maghrib => appText.prayerMaghrib,
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

/// The six traditional named parts of the day, used in place of AM/PM on the
/// prayer-time cards — সুবহে সাদিক, সকাল, দুপুর, বিকেল, সন্ধ্যা, রাত.
enum DayPeriodName { subheSadik, sokal, dupur, bikel, sondhya, raat }

extension DayPeriodNameLabel on DayPeriodName {
  String displayName(AppText appText) => switch (this) {
    DayPeriodName.subheSadik => appText.periodSubheSadik,
    DayPeriodName.sokal => appText.periodSokal,
    DayPeriodName.dupur => appText.periodDupur,
    DayPeriodName.bikel => appText.periodBikel,
    DayPeriodName.sondhya => appText.periodSondhya,
    DayPeriodName.raat => appText.periodRaat,
  };
}

/// Which of [DayPeriodName] [time] falls in, from the day's actual prayer
/// times — so the boundaries move with the sun through the year and with
/// location/season, rather than sitting at fixed clock hours:
///
///  [fajr, sunrise)  -> subheSadik   [sunrise, dhuhr) -> sokal
///  [dhuhr, asr)      -> dupur        [asr, maghrib)   -> bikel
///  [maghrib, isha)   -> sondhya      [isha, fajr)      -> raat
DayPeriodName dayPeriodNameFor(PrayerClockTime time, DailyPrayerTimes times) {
  final minute = time.totalMinutes;
  if (minute < times.fajr.totalMinutes) return DayPeriodName.raat;
  if (minute < times.sunrise.totalMinutes) return DayPeriodName.subheSadik;
  if (minute < times.dhuhr.totalMinutes) return DayPeriodName.sokal;
  if (minute < times.asr.totalMinutes) return DayPeriodName.dupur;
  if (minute < times.maghrib.totalMinutes) return DayPeriodName.bikel;
  if (minute < times.isha.totalMinutes) return DayPeriodName.sondhya;
  return DayPeriodName.raat;
}

/// `সুবহে সাদিক ৫:২৩` / `Morning 5:23` — [time]'s [DayPeriodName] in place of
/// AM/PM, before its digits. Falls back to the digits alone when [times]
/// (today's prayer times) hasn't loaded yet, since the day-part can't be
/// determined without it.
String localizedPeriodClock(
  PrayerClockTime time, {
  required DailyPrayerTimes? times,
  required AppText appText,
  required bool bangla,
}) {
  final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final digits = localizeDigits(
    '$hour12:${time.minute.toString().padLeft(2, '0')}',
    bangla: bangla,
  );
  if (times == null) return digits;
  return '${dayPeriodNameFor(time, times).displayName(appText)} $digits';
}
