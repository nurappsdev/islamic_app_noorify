/// `GET /amol/analytics/graph`'s `range` object: the actual date window the
/// server resolved the response for (which may not exactly match the
/// `startDate`/`endDate` the request asked for, e.g. clamped to today).
class AmolAnalyticsRange {
  const AmolAnalyticsRange({
    required this.startDate,
    required this.endDate,
    required this.formattedRange,
    required this.numDays,
  });

  final String startDate;
  final String endDate;
  final String formattedRange;
  final int numDays;
}

/// `GET /amol/analytics/graph`'s `navigation` object: lets the client step
/// to the adjacent window without recomputing dates itself.
class AmolAnalyticsNavigation {
  const AmolAnalyticsNavigation({
    required this.currentOffset,
    required this.previousOffset,
    required this.nextOffset,
    required this.hasPrevious,
    required this.hasNext,
  });

  final int currentOffset;
  final int? previousOffset;
  final int? nextOffset;
  final bool hasPrevious;
  final bool hasNext;
}
