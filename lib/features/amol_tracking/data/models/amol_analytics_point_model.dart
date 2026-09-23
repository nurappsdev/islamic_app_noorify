import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_point.dart';

/// Data-layer representation of [AmolAnalyticsPoint], parsed from one entry
/// of `GET /amol/analytics/graph`'s `pillarsComparison` array, e.g.
/// `{pillarKey: fardh_prayer, title: Fardh Prayer, titleBn: "ফরজ নামাজ",
/// myScore: 2, competitorScore: 1.7, maxScore: 7}`.
class AmolAnalyticsPointModel extends AmolAnalyticsPoint {
  const AmolAnalyticsPointModel({
    required super.pillarKey,
    required super.title,
    required super.titleBn,
    required super.myScore,
    required super.competitorScore,
    required super.maxScore,
  });

  factory AmolAnalyticsPointModel.fromJson(Map<String, dynamic> json) {
    return AmolAnalyticsPointModel(
      pillarKey: json['pillarKey']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      titleBn: json['titleBn']?.toString() ?? '',
      myScore: (json['myScore'] as num?) ?? 0,
      // Left null (not defaulted to 0) when the server omits it, so the
      // chart can skip drawing a competitor point there instead of
      // plotting a misleading zero.
      competitorScore: json['competitorScore'] as num?,
      maxScore: (json['maxScore'] as num?) ?? 0,
    );
  }
}
