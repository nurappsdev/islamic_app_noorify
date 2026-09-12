import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_daily_summary.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_pillar.dart';

/// The full payload of `GET /amol/tracker/daily?date=YYYY-MM-DD`.
class AmolDailyDashboard {
  const AmolDailyDashboard({
    required this.dateFormatted,
    required this.dateIso,
    required this.earnedPoints,
    required this.maxPoints,
    required this.completionPercentage,
    required this.summary,
    required this.pillars,
  });

  final String dateFormatted;
  final String dateIso;
  final num earnedPoints;
  final num maxPoints;
  final num completionPercentage;
  final AmolDailySummary summary;
  final List<AmolPillar> pillars;
}
