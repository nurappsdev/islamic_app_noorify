import 'package:islami_app_noorify/features/amol_tracking/data/models/amol_analytics_point_model.dart';
import 'package:islami_app_noorify/features/amol_tracking/data/models/amol_analytics_range_model.dart';
import 'package:islami_app_noorify/features/amol_tracking/data/models/amol_analytics_summary_model.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_graph.dart';

/// Data-layer representation of [AmolAnalyticsGraph], parsed from the `data`
/// payload of `GET /amol/analytics/graph`, e.g.:
/// ```
/// {timeframe: daily, title: "Wednesday 23 September, 2026 - ...",
///  subtitle: "1 Days - Custom Range Spiritual Progress (vs. Yousuf Ahmed)",
///  yAxisMax: 12, myTotalPoints: 12, competitorTotalPoints: 27.4,
///  competitorName: "Yousuf Ahmed",
///  range: {startDate: ..., endDate: ..., formattedRange: ..., numDays: ...},
///  navigation: {currentOffset: 0, previousOffset: 1, nextOffset: null,
///               hasPrevious: true, hasNext: false},
///  pillarsComparison: [{pillarKey: fardh_prayer, ...}, ...]}
/// ```
class AmolAnalyticsGraphModel extends AmolAnalyticsGraph {
  const AmolAnalyticsGraphModel({
    required super.timeframe,
    required super.title,
    required super.subtitle,
    required super.yAxisMax,
    required super.myTotalPoints,
    required super.competitorTotalPoints,
    required super.competitorName,
    required super.pillars,
    super.range,
    super.navigation,
    super.summary,
    super.todaysTrack,
    super.myName,
    super.earnedPoints,
    super.maxPoints,
    super.serverCompletionPercentage,
  });

  factory AmolAnalyticsGraphModel.fromJson(Map<String, dynamic> json) {
    final rawPillars = json['pillarsComparison'];
    final pillars = rawPillars is List
        ? rawPillars
              .whereType<Map>()
              .map(
                (e) => AmolAnalyticsPointModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : const <AmolAnalyticsPointModel>[];

    final rawRange = json['range'];
    final range = rawRange is Map
        ? AmolAnalyticsRangeModel.fromJson(Map<String, dynamic>.from(rawRange))
        : null;

    final rawNavigation = json['navigation'];
    final navigation = rawNavigation is Map
        ? AmolAnalyticsNavigationModel.fromJson(
            Map<String, dynamic>.from(rawNavigation),
          )
        : null;

    final rawSummary = json['summary'];
    final summary = rawSummary is Map
        ? AmolAnalyticsSummaryModel.fromJson(
            Map<String, dynamic>.from(rawSummary),
          )
        : null;

    final rawTodaysTrack = json['todaysAmolTrack'];
    final todaysTrack = rawTodaysTrack is Map
        ? AmolAnalyticsTodaysTrackModel.fromJson(
            Map<String, dynamic>.from(rawTodaysTrack),
          )
        : null;

    return AmolAnalyticsGraphModel(
      timeframe: json['timeframe']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      yAxisMax: (json['yAxisMax'] as num?) ?? 12,
      myTotalPoints: (json['myTotalPoints'] as num?) ?? 0,
      competitorTotalPoints: (json['competitorTotalPoints'] as num?) ?? 0,
      competitorName: json['competitorName']?.toString() ?? '',
      pillars: pillars,
      range: range,
      navigation: navigation,
      summary: summary,
      todaysTrack: todaysTrack,
      // `myName`/`userName` are the same value; either can be present.
      myName: (json['myName'] ?? json['userName'])?.toString(),
      earnedPoints: json['earnedPoints'] as num?,
      maxPoints: json['maxPoints'] as num?,
      serverCompletionPercentage: json['completionPercentage'] as num?,
    );
  }
}
