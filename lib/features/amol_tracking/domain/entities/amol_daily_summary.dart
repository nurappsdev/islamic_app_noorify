/// The day's overall point summary from `GET /amol/tracker/daily`.
class AmolDailySummary {
  const AmolDailySummary({
    required this.totalEarnedPoints,
    required this.totalPossiblePoints,
    required this.percentage,
    required this.pointsText,
  });

  final num totalEarnedPoints;
  final num totalPossiblePoints;
  final num percentage;

  /// Server-formatted text (e.g. `"Point : 2/40"`).
  final String pointsText;

  AmolDailySummary copyWith({
    num? totalEarnedPoints,
    num? percentage,
    String? pointsText,
  }) => AmolDailySummary(
    totalEarnedPoints: totalEarnedPoints ?? this.totalEarnedPoints,
    totalPossiblePoints: totalPossiblePoints,
    percentage: percentage ?? this.percentage,
    pointsText: pointsText ?? this.pointsText,
  );
}
