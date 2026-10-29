/// Dua reading earns half a point for every complete five minutes read in a
/// day, one point at most — the rule `POST /duas/reading/track` documents
/// ("every whole 5 minutes in a day is 0.5 point, so 10 minutes earns the
/// full 1"), and the same numbers the Amol checklist sends with the Dua
/// item's own `entry` block (`entrySize: 5`, `entryPoints: 0.5`,
/// `maxEntries: 2`).
///
/// The rule is daily and cumulative: six sessions of one minute each earn
/// the same half point one six-minute session does. Points are therefore
/// always derived from the day's total seconds, never rounded per session —
/// otherwise two four-minute sessions would earn nothing where eight
/// minutes in a row earn half a point.
const kDuaReadingSecondsPerEntry = 5 * 60;

/// What one complete [kDuaReadingSecondsPerEntry] earns.
const kDuaReadingPointsPerEntry = 0.5;

/// Beyond this, more reading earns nothing (ten minutes is the full point).
const kDuaReadingMaxEntriesPerDay = 2;

/// The most one day of dua reading can earn.
const kDuaReadingMaxDailyPoints =
    kDuaReadingPointsPerEntry * kDuaReadingMaxEntriesPerDay;

/// Shorter sessions are not reported: `/duas/reading/track` requires at
/// least this many seconds, which is also when the reader's "Read" checkbox
/// appears.
const kDuaReadingMinReportSeconds = 30;

/// The most one report may carry (the API's own cap).
const kDuaReadingMaxReportSeconds = 7200;

/// The points [seconds] of dua reading earn within one day.
num duaReadingPointsForSeconds(int seconds) {
  if (seconds <= 0) return 0;
  final entries = seconds ~/ kDuaReadingSecondsPerEntry;
  final earned = entries > kDuaReadingMaxEntriesPerDay
      ? kDuaReadingMaxEntriesPerDay
      : entries;
  return earned * kDuaReadingPointsPerEntry;
}
