/// The time window of the reading dashboard.
enum HadithHistoryPeriod { daily, weekly, monthly }

/// The `from` / `to` dates (date-only, inclusive) requested for [period]:
/// daily is [endDate] alone, weekly is [endDate] and the 6 days before it (7
/// days total), and monthly is the 30 days before [endDate] up to it.
/// [endDate] defaults to today, so the daily/weekly arrows can step the
/// window back (and forward, up to today) without changing [now].
({DateTime from, DateTime to}) hadithHistoryRange(
  HadithHistoryPeriod period, {
  DateTime? now,
  DateTime? endDate,
}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final end = endDate ?? today;
  final daysBack = switch (period) {
    HadithHistoryPeriod.daily => 0,
    HadithHistoryPeriod.weekly => 6,
    HadithHistoryPeriod.monthly => 30,
  };
  return (
    // Calendar arithmetic (not a Duration), so daylight saving can't shift it.
    from: DateTime(end.year, end.month, end.day - daysBack),
    to: end,
  );
}

/// The `from` / `to` dates (date-only, inclusive) of the calendar [month] (any
/// date in it): the 1st to the last day, or to today for the current month, as
/// nothing can be read in the future.
({DateTime from, DateTime to}) hadithMonthRange(
  DateTime month, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final from = DateTime(month.year, month.month, 1);
  // Day 0 of the next month is the last day of this one.
  final last = DateTime(month.year, month.month + 1, 0);
  return (from: from, to: last.isAfter(today) ? today : last);
}

/// One day of `GET /learning/reading/history`.
class HadithReadingDay {
  const HadithReadingDay({
    required this.date,
    required this.readMinutes,
    required this.goalMinutes,
    required this.hadithsRead,
    this.points,
  });

  /// Date only (no time part).
  final DateTime date;

  /// Minutes actually read that day — the progress.
  final double readMinutes;

  /// The user's reading goal for that day, in minutes.
  final double goalMinutes;
  final int hadithsRead;

  /// Points earned that day; null when the backend doesn't send them.
  final double? points;
}

/// The totals over the whole requested range.
class HadithReadingTotals {
  const HadithReadingTotals({
    required this.totalMinutes,
    required this.hadithsRead,
    required this.pointsText,
    required this.progressText,
    this.totalPoints,
  });

  final double totalMinutes;
  final int hadithsRead;

  /// Points over the whole range; null when neither the backend nor any day
  /// has them.
  final double? totalPoints;

  /// Ready-made display texts from the backend; empty when it sent none.
  final String pointsText;
  final String progressText;
}

class HadithReadingHistory {
  const HadithReadingHistory({required this.days, required this.totals});

  final List<HadithReadingDay> days;
  final HadithReadingTotals totals;
}
