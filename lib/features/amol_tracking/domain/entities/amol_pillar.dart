import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_item.dart';

/// One deed-pillar's daily checklist (Fardh Prayer, Quran, ...) from
/// `GET /amol/tracker/daily`.
class AmolPillar {
  const AmolPillar({
    required this.pillarKey,
    required this.title,
    required this.earnedPoints,
    required this.maxPoints,
    required this.percentage,
    required this.formattedSubtext,
    required this.items,
  });

  final String pillarKey;
  final String title;
  final num earnedPoints;
  final num maxPoints;
  final num percentage;

  /// Server-formatted progress text (e.g. `"2/7"`).
  final String formattedSubtext;
  final List<AmolItem> items;
}
