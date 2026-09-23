import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_summary.dart';

/// Data-layer representation of [AmolAnalyticsSummary], parsed from
/// `GET /amol/analytics/graph`'s `summary` object, e.g.
/// `{title: "Weekly Amol track", totalEarnedPoints: 87.5,
/// totalPossiblePoints: 320, percentage: 27, pointsText: "Point : 87.5/320"}`.
class AmolAnalyticsSummaryModel extends AmolAnalyticsSummary {
  const AmolAnalyticsSummaryModel({
    required super.title,
    required super.totalEarnedPoints,
    required super.totalPossiblePoints,
    required super.percentage,
    required super.pointsText,
  });

  factory AmolAnalyticsSummaryModel.fromJson(Map<String, dynamic> json) {
    return AmolAnalyticsSummaryModel(
      title: json['title']?.toString() ?? '',
      totalEarnedPoints: (json['totalEarnedPoints'] as num?) ?? 0,
      totalPossiblePoints: (json['totalPossiblePoints'] as num?) ?? 0,
      percentage: (json['percentage'] as num?) ?? 0,
      pointsText: json['pointsText']?.toString() ?? '',
    );
  }
}

/// Data-layer representation of [AmolAnalyticsTodaysTrack], parsed from
/// `GET /amol/analytics/graph`'s `todaysAmolTrack` object, e.g.
/// `{title: "Todays Amol track", date: "2026-09-23", earnedPoints: 12,
/// maxPoints: 40, completionPercentage: 30, pointsText: "Point : 12/40"}`.
class AmolAnalyticsTodaysTrackModel extends AmolAnalyticsTodaysTrack {
  const AmolAnalyticsTodaysTrackModel({
    required super.title,
    required super.date,
    required super.earnedPoints,
    required super.maxPoints,
    required super.completionPercentage,
    required super.pointsText,
  });

  factory AmolAnalyticsTodaysTrackModel.fromJson(Map<String, dynamic> json) {
    return AmolAnalyticsTodaysTrackModel(
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      earnedPoints: (json['earnedPoints'] as num?) ?? 0,
      maxPoints: (json['maxPoints'] as num?) ?? 0,
      completionPercentage: (json['completionPercentage'] as num?) ?? 0,
      pointsText: json['pointsText']?.toString() ?? '',
    );
  }
}
