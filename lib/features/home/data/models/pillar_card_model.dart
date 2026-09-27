import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/home/domain/entities/pillar_card.dart';

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
  });

  factory PillarCardModel.fromJson(Map<String, dynamic> json) {
    final localized = json['localized'];
    final localizedJson = localized is Map
        ? localized
        : const <String, dynamic>{};
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
    );
  }
}
