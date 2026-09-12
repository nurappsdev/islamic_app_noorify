import 'package:islami_app_noorify/features/amol_tracking/data/models/amol_item_model.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_pillar.dart';

class AmolPillarModel extends AmolPillar {
  const AmolPillarModel({
    required super.pillarKey,
    required super.title,
    required super.earnedPoints,
    required super.maxPoints,
    required super.percentage,
    required super.formattedSubtext,
    required super.items,
  });

  factory AmolPillarModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    return AmolPillarModel(
      pillarKey: json['pillarKey']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      earnedPoints: (json['earnedPoints'] as num?) ?? 0,
      maxPoints: (json['maxPoints'] as num?) ?? 0,
      percentage: (json['percentage'] as num?) ?? 0,
      formattedSubtext: json['formattedSubtext']?.toString() ?? '',
      items: items is List
          ? items
              .whereType<Map>()
              .map((e) => AmolItemModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
