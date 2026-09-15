import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_point.dart';

/// The full payload of
/// `GET /amol/analytics/graph?date=YYYY-MM-DD&timeframe=daily|weekly|monthly`.
class AmolAnalyticsGraph {
  const AmolAnalyticsGraph({
    required this.timeframe,
    required this.title,
    required this.subtitle,
    required this.yAxisMax,
    required this.myTotalPoints,
    required this.competitorTotalPoints,
    required this.competitorName,
    required this.pillars,
  });

  final String timeframe;
  final String title;
  final String subtitle;
  final num yAxisMax;
  final num myTotalPoints;
  final num competitorTotalPoints;
  final String competitorName;
  final List<AmolAnalyticsPoint> pillars;

  /// The API has no single "total possible points" field — only each
  /// pillar's `maxScore` — so the summary card's "earned/max" label sums
  /// them here.
  num get maxTotalPoints =>
      pillars.fold<num>(0, (sum, pillar) => sum + pillar.maxScore);

  num get completionPercentage =>
      maxTotalPoints == 0 ? 0 : (myTotalPoints / maxTotalPoints) * 100;

  /// This user's score for [pillarKey], or `0` when the server didn't
  /// include that pillar.
  num valueFor(String pillarKey) {
    for (final pillar in pillars) {
      if (pillar.pillarKey == pillarKey) return pillar.myScore;
    }
    return 0;
  }

  /// The nearest competitor's score for [pillarKey], or `null` when the
  /// server didn't include that pillar.
  num? competitorValueFor(String pillarKey) {
    for (final pillar in pillars) {
      if (pillar.pillarKey == pillarKey) return pillar.competitorScore;
    }
    return null;
  }
}
