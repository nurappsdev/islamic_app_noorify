import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_range.dart';

/// Data-layer representation of [AmolAnalyticsRange], parsed from
/// `GET /amol/analytics/graph`'s `range` object, e.g.
/// `{startDate: "2026-09-17", endDate: "2026-09-23",
/// formattedRange: "17 Sep 2026 - 23 Sep 2026", numDays: 7}`.
class AmolAnalyticsRangeModel extends AmolAnalyticsRange {
  const AmolAnalyticsRangeModel({
    required super.startDate,
    required super.endDate,
    required super.formattedRange,
    required super.numDays,
  });

  factory AmolAnalyticsRangeModel.fromJson(Map<String, dynamic> json) {
    return AmolAnalyticsRangeModel(
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      formattedRange: json['formattedRange']?.toString() ?? '',
      numDays: (json['numDays'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Data-layer representation of [AmolAnalyticsNavigation], parsed from
/// `GET /amol/analytics/graph`'s `navigation` object, e.g.
/// `{currentOffset: 0, previousOffset: 1, nextOffset: null,
/// hasPrevious: true, hasNext: false}`.
class AmolAnalyticsNavigationModel extends AmolAnalyticsNavigation {
  const AmolAnalyticsNavigationModel({
    required super.currentOffset,
    required super.previousOffset,
    required super.nextOffset,
    required super.hasPrevious,
    required super.hasNext,
  });

  factory AmolAnalyticsNavigationModel.fromJson(Map<String, dynamic> json) {
    return AmolAnalyticsNavigationModel(
      currentOffset: (json['currentOffset'] as num?)?.toInt() ?? 0,
      previousOffset: (json['previousOffset'] as num?)?.toInt(),
      nextOffset: (json['nextOffset'] as num?)?.toInt(),
      hasPrevious: json['hasPrevious'] as bool? ?? false,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }
}
