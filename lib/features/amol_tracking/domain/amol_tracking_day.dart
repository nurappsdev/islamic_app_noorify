import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';

/// Resolves the API date for Amol tracking.
///
/// A tracking day starts at that civil date's Fajr and ends immediately before
/// the next Fajr. Therefore, the hours after midnight and before Fajr belong
/// to the preceding `YYYY-MM-DD` record.
DateTime amolTrackingDate(DateTime now, DailyPrayerTimes times) {
  final fajrToday = DateTime(
    now.year,
    now.month,
    now.day,
    times.fajr.hour,
    times.fajr.minute,
  );
  final civilDate = DateTime(now.year, now.month, now.day);
  return now.isBefore(fajrToday)
      ? civilDate.subtract(const Duration(days: 1))
      : civilDate;
}

String amolTrackingDateIso(DateTime now, DailyPrayerTimes times) =>
    isoDate(amolTrackingDate(now, times));

String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// The next point at which the current civil day's Fajr data must be
/// re-evaluated. Before Fajr it is Fajr itself; after Fajr, midnight is used
/// to obtain the next civil day's dynamically calculated Fajr time.
DateTime nextAmolTrackingCheck(DateTime now, DailyPrayerTimes times) {
  final fajrToday = DateTime(
    now.year,
    now.month,
    now.day,
    times.fajr.hour,
    times.fajr.minute,
  );
  if (now.isBefore(fajrToday)) return fajrToday;
  return DateTime(now.year, now.month, now.day + 1);
}
