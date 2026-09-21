/// The time window of the reading dashboard.
enum HadithHistoryPeriod { daily, weekly, monthly }

/// The `from` / `to` dates (date-only, inclusive) requested for [period]:
/// daily is today alone, weekly is the 7 days before today up to today, and
/// monthly is the 30 days before today up to today.
({DateTime from, DateTime to}) hadithHistoryRange(
  HadithHistoryPeriod period, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final daysBack = switch (period) {
    HadithHistoryPeriod.daily => 0,
    HadithHistoryPeriod.weekly => 7,
    HadithHistoryPeriod.monthly => 30,
  };
  return (
    // Calendar arithmetic (not a Duration), so daylight saving can't shift it.
    from: DateTime(today.year, today.month, today.day - daysBack),
    to: today,
  );
}

/// One day of `GET /learning/reading/history`.
class HadithReadingDay {
  const HadithReadingDay({
    required this.date,
    required this.readMinutes,
    required this.goalMinutes,
    required this.hadithsRead,
  });

  /// Date only (no time part).
  final DateTime date;

  /// Minutes actually read that day — the progress.
  final double readMinutes;

  /// The user's reading goal for that day, in minutes.
  final double goalMinutes;
  final int hadithsRead;
}

/// The totals over the whole requested range.
class HadithReadingTotals {
  const HadithReadingTotals({
    required this.totalMinutes,
    required this.hadithsRead,
    required this.pointsText,
    required this.progressText,
  });

  final double totalMinutes;
  final int hadithsRead;

  /// Ready-made display texts from the backend; empty when it sent none.
  final String pointsText;
  final String progressText;
}

class HadithReadingHistory {
  const HadithReadingHistory({required this.days, required this.totals});

  final List<HadithReadingDay> days;
  final HadithReadingTotals totals;
}
