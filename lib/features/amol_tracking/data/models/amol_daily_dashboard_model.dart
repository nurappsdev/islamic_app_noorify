import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/features/amol_tracking/data/models/amol_daily_summary_model.dart';
import 'package:islami_app_noorify/features/amol_tracking/data/models/amol_pillar_model.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';

/// Data-layer representation of [AmolDailyDashboard], parsed from the `data`
/// payload of `GET /amol/tracker/daily?date=YYYY-MM-DD`.
class AmolDailyDashboardModel extends AmolDailyDashboard {
  const AmolDailyDashboardModel({
    required super.dateFormatted,
    required super.dateIso,
    required super.earnedPoints,
    required super.maxPoints,
    required super.completionPercentage,
    required super.summary,
    required super.pillars,
  });

  factory AmolDailyDashboardModel.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'];
    if (summaryJson is! Map<String, dynamic>) {
      throw ParsingException('Amol daily response is missing "summary".');
    }

    final pillars = json['pillars'];

    return AmolDailyDashboardModel(
      dateFormatted: json['dateFormatted']?.toString() ?? '',
      dateIso: json['dateIso']?.toString() ?? '',
      earnedPoints: (json['earnedPoints'] as num?) ?? 0,
      maxPoints: (json['maxPoints'] as num?) ?? 0,
      completionPercentage: (json['completionPercentage'] as num?) ?? 0,
      summary: AmolDailySummaryModel.fromJson(summaryJson),
      pillars: pillars is List
          ? pillars
                .whereType<Map>()
                .map(
                  (e) => AmolPillarModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}
