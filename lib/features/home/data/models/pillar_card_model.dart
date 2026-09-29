import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/home/domain/entities/pillar_card.dart';

class PillarCardModel extends PillarCard {
  const PillarCardModel({
    required super.pillarKey,
    required super.title,
    required super.points,
    required super.maxPoints,
    required super.percentage,
    required super.formattedSubtext,
    super.localizedTitle,
    super.localizedPoints,
    super.localizedMaxPoints,
    super.localizedPercentage,
    super.localizedFormattedSubtext,
    super.localizedChartLabels,
  });

  factory PillarCardModel.fromJson(Map<String, dynamic> json) {
    final localized = json['localized'];
    final localizedJson = localized is Map
        ? localized
        : const <String, dynamic>{};
    final chartData = localizedJson['chartData'];
    final chartLabels = <String, LocalizedText>{
      if (chartData is Map)
        for (final entry in chartData.entries)
          if (entry.key is String && entry.value is Map)
            entry.key as String: LocalizedText.fromJson(
              (entry.value as Map)['label'],
            ),
    };
    return PillarCardModel(
      pillarKey: json['pillarKey']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      points: (json['points'] as num?) ?? 0,
      maxPoints: (json['maxPoints'] as num?) ?? 0,
      percentage: (json['percentage'] as num?) ?? 0,
      formattedSubtext: json['formattedSubtext']?.toString() ?? '',
      localizedTitle: LocalizedText.fromJson(localizedJson['title']),
      localizedPoints: LocalizedText.fromJson(localizedJson['points']),
      localizedMaxPoints: LocalizedText.fromJson(localizedJson['maxPoints']),
      localizedPercentage: LocalizedText.fromJson(localizedJson['percentage']),
      localizedFormattedSubtext: LocalizedText.fromJson(
        localizedJson['formattedSubtext'],
      ),
      localizedChartLabels: chartLabels,
    );
  }
}
