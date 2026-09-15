/// One pillar's row in `GET /amol/analytics/graph`'s `pillarsComparison`.
class AmolAnalyticsPoint {
  const AmolAnalyticsPoint({
    required this.pillarKey,
    required this.title,
    required this.myScore,
    required this.competitorScore,
    required this.maxScore,
  });

  final String pillarKey;
  final String title;
  final num myScore;
  final num competitorScore;
  final num maxScore;
}
