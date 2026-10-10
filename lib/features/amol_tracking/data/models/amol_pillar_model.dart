import 'package:tuhfatul_muslim/features/amol_tracking/data/models/amol_item_model.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pillar.dart';

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

  /// `pillarKey` -> `itemKey`s to hide, even though the server still sends
  /// them (e.g. Asr Sunnah was dropped from the Sunnah and Witr checklist).
  static const _hiddenItemKeysByPillar = {
    'sunnah_witr': {'asr_sunnah'},
  };

  factory AmolPillarModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final pillarKey = json['pillarKey']?.toString() ?? '';
    final hidden = _hiddenItemKeysByPillar[pillarKey];
    return AmolPillarModel(
      pillarKey: pillarKey,
      title: json['title']?.toString() ?? '',
      earnedPoints: (json['earnedPoints'] as num?) ?? 0,
      maxPoints: (json['maxPoints'] as num?) ?? 0,
      percentage: (json['percentage'] as num?) ?? 0,
      formattedSubtext: json['formattedSubtext']?.toString() ?? '',
      items: items is List
          ? items
                .whereType<Map>()
                .map(
                  (e) => AmolItemModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .where((item) => hidden == null || !hidden.contains(item.itemKey))
                .toList()
          : const [],
    );
  }
}
