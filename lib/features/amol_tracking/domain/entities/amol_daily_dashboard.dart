import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_summary.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pillar.dart';

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
    this.pendingItemKeys = const {},
  });

  final String dateFormatted;
  final String dateIso;
  final num earnedPoints;
  final num maxPoints;
  final num completionPercentage;
  final AmolDailySummary summary;
  final List<AmolPillar> pillars;

  /// The `itemKey`s whose state was set on this device and has not reached
  /// the server yet. Filled in by the repository from the offline queue (a
  /// parsed API response never carries any).
  ///
  /// Deliberately **not** shown anywhere: an item saved offline is drawn
  /// exactly like one the server has already recorded. It is kept because it
  /// is what tells the data layer, and its tests, that the queue has been
  /// applied to this day — not as something for the UI to render.
  final Set<String> pendingItemKeys;

  bool isPending(String itemKey) => pendingItemKeys.contains(itemKey);

  AmolDailyDashboard copyWith({
    String? dateIso,
    String? dateFormatted,
    num? earnedPoints,
    num? completionPercentage,
    AmolDailySummary? summary,
    List<AmolPillar>? pillars,
    Set<String>? pendingItemKeys,
  }) => AmolDailyDashboard(
    dateFormatted: dateFormatted ?? this.dateFormatted,
    dateIso: dateIso ?? this.dateIso,
    earnedPoints: earnedPoints ?? this.earnedPoints,
    maxPoints: maxPoints,
    completionPercentage: completionPercentage ?? this.completionPercentage,
    summary: summary ?? this.summary,
    pillars: pillars ?? this.pillars,
    pendingItemKeys: pendingItemKeys ?? this.pendingItemKeys,
  );
}
