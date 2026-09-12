import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_daily_summary.dart';

class AmolDailySummaryModel extends AmolDailySummary {
  const AmolDailySummaryModel({
    required super.totalEarnedPoints,
    required super.totalPossiblePoints,
    required super.percentage,
    required super.pointsText,
  });

  factory AmolDailySummaryModel.fromJson(Map<String, dynamic> json) {
    return AmolDailySummaryModel(
      totalEarnedPoints: (json['totalEarnedPoints'] as num?) ?? 0,
      totalPossiblePoints: (json['totalPossiblePoints'] as num?) ?? 0,
      percentage: (json['percentage'] as num?) ?? 0,
      pointsText: json['pointsText']?.toString() ?? '',
    );
  }
}
