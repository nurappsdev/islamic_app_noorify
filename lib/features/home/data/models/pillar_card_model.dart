import 'package:islami_app_noorify/features/home/domain/entities/pillar_card.dart';

class PillarCardModel extends PillarCard {
  const PillarCardModel({
    required super.pillarKey,
    required super.title,
    required super.points,
    required super.maxPoints,
    required super.percentage,
    required super.formattedSubtext,
  });

  factory PillarCardModel.fromJson(Map<String, dynamic> json) {
    return PillarCardModel(
      pillarKey: json['pillarKey']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      points: (json['points'] as num?) ?? 0,
      maxPoints: (json['maxPoints'] as num?) ?? 0,
      percentage: (json['percentage'] as num?) ?? 0,
      formattedSubtext: json['formattedSubtext']?.toString() ?? '',
    );
  }
}
