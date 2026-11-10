/// `GET /amol/analytics/graph`'s `summary` object: the server's own
/// earned/possible points and percentage for the requested window, already
/// formatted into [pointsText] (e.g. `"Point : 87.5/320"`) so the UI
/// doesn't need to re-derive it from [totalEarnedPoints]/[totalPossiblePoints].
class AmolAnalyticsSummary {
  const AmolAnalyticsSummary({
    required this.title,
    required this.totalEarnedPoints,
    required this.totalPossiblePoints,
    required this.percentage,
    required this.pointsText,
  });

  final String title;
  final num totalEarnedPoints;
  final num totalPossiblePoints;
  final num percentage;
  final String pointsText;
}

/// `GET /amol/analytics/graph`'s `todaysAmolTrack` object: today's own
/// progress, included alongside whichever window (daily/weekly/monthly)
/// was actually requested.
class AmolAnalyticsTodaysTrack {
  const AmolAnalyticsTodaysTrack({
    required this.title,
    required this.date,
    required this.earnedPoints,
    required this.maxPoints,
    required this.completionPercentage,
    required this.pointsText,
  });

  final String title;
  final String date;
  final num earnedPoints;
  final num maxPoints;
  final num completionPercentage;
  final String pointsText;
}
