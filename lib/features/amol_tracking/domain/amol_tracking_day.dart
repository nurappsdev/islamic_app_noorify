/// The day every Daily Amol feature is grouped by: the **Gregorian (English)
/// calendar day in the device's own timezone**.
///
/// A tracking day runs from 00:00:00 to 23:59:59 local time. At midnight the
/// next day begins with an empty checklist and zero points, and the day that
/// just ended is closed: its records stay exactly as they were, on the server
/// and in this device's storage, and nothing may be logged against it any
/// more.
///
/// Every part of the app resolves the day through this one place — the Home
/// dashboard, the Amol tracker, the offline queue and the background sync —
/// so a tick, a reading minute and a card can never disagree about which day
/// they belong to. [AmolDayClock] watches the clock and announces the
/// rollover; these functions are the arithmetic behind it.
library;

/// The calendar day of [now], with the time of day dropped.
DateTime amolTrackingDate(DateTime now) =>
    DateTime(now.year, now.month, now.day);

/// The `YYYY-MM-DD` the API records [now]'s Amol under.
String amolTrackingDateIso(DateTime now) => isoDate(amolTrackingDate(now));

String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// The next midnight after [now] — the moment the tracking day rolls over and
/// every daily view has to start again from zero.
///
/// Built from the calendar rather than by adding 24 hours, so a day that is
/// shorter or longer than 24 hours (a daylight-saving change) still rolls
/// over at its own local midnight.
DateTime nextAmolTrackingCheck(DateTime now) =>
    DateTime(now.year, now.month, now.day + 1);
