import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_item.dart';

class AmolItemModel extends AmolItem {
  const AmolItemModel({
    required super.itemKey,
    required super.title,
    required super.points,
    required super.maxPoints,
    required super.isCompleted,
  });

  factory AmolItemModel.fromJson(Map<String, dynamic> json) {
    return AmolItemModel(
      itemKey: json['itemKey']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      points: (json['points'] as num?) ?? 0,
      maxPoints: (json['maxPoints'] as num?) ?? 0,
      isCompleted: json['isCompleted'] == true,
    );
  }
}
