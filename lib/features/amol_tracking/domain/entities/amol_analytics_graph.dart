import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_point.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_range.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_summary.dart';

/// The full payload of
/// `GET /amol/analytics/graph?timeframe=daily|weekly|monthly&startDate=YYYY-MM-DD&endDate=YYYY-MM-DD&offset=N`.
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
    this.range,
    this.navigation,
    this.summary,
    this.todaysTrack,
    this.myName,
    this.earnedPoints,
    this.maxPoints,
    this.serverCompletionPercentage,
  });

  final String timeframe;
  final String title;
  final String subtitle;
  final num yAxisMax;
  final num myTotalPoints;
  final num competitorTotalPoints;
  final String competitorName;
  final List<AmolAnalyticsPoint> pillars;

  /// The date window the server actually resolved this response for.
  final AmolAnalyticsRange? range;

  /// Lets the UI step to the adjacent window and disable a direction once
  /// the server says there's nothing further that way.
  final AmolAnalyticsNavigation? navigation;

  /// The server's own earned/possible points + percentage for this window,
  /// already formatted into `pointsText` — prefer this over
  /// [maxTotalPoints]/[completionPercentage] (which only approximate it by
  /// summing [pillars]) whenever it's present.
  final AmolAnalyticsSummary? summary;

  /// Today's progress, included alongside whichever window was requested.
  final AmolAnalyticsTodaysTrack? todaysTrack;

  /// The signed-in user's name as the server knows it (`myName`/`userName`
  /// in the response — both the same value).
  final String? myName;

  /// Top-level `earnedPoints`/`maxPoints`/`completionPercentage` — the same
  /// numbers [summary] carries, kept here too since the API exposes both.
  final num? earnedPoints;
  final num? maxPoints;
  final num? serverCompletionPercentage;

  /// The API has no single "total possible points" field — only each
  /// pillar's `maxScore` — so the summary card's "earned/max" label sums
  /// them here. Only a fallback for when the server's own [summary]/
  /// [maxPoints] aren't present.
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
