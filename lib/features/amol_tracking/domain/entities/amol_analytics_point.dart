/// One pillar's row in `GET /amol/analytics/graph`'s `pillarsComparison`.
class AmolAnalyticsPoint {
  const AmolAnalyticsPoint({
    required this.pillarKey,
    required this.title,
    required this.titleBn,
    required this.myScore,
    required this.competitorScore,
    required this.maxScore,
  });

  final String pillarKey;
  final String title;
  final String titleBn;
  final num myScore;

  /// `null` when the server has no competitor score for this pillar (the
  /// chart skips drawing a bubble/line segment there).
  final num? competitorScore;
  final num maxScore;
}
