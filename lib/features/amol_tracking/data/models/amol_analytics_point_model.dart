import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_point.dart';

/// Data-layer representation of [AmolAnalyticsPoint], parsed from one entry
/// of `GET /amol/analytics/graph`'s `pillarsComparison` array, e.g.
/// `{pillarKey: fardh_prayer, title: Fardh Prayer, myScore: 2,
/// competitorScore: 1.7, maxScore: 7}`.
class AmolAnalyticsPointModel extends AmolAnalyticsPoint {
  const AmolAnalyticsPointModel({
    required super.pillarKey,
    required super.title,
    required super.myScore,
    required super.competitorScore,
    required super.maxScore,
  });

  factory AmolAnalyticsPointModel.fromJson(Map<String, dynamic> json) {
    return AmolAnalyticsPointModel(
      pillarKey: json['pillarKey']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      myScore: (json['myScore'] as num?) ?? 0,
      competitorScore: (json['competitorScore'] as num?) ?? 0,
      maxScore: (json['maxScore'] as num?) ?? 0,
    );
  }
}
