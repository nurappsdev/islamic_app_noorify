import 'package:islami_app_noorify/features/home/domain/entities/highlight_card.dart';

class HighlightCardModel extends HighlightCard {
  const HighlightCardModel({
    required super.id,
    required super.type,
    required super.title,
    super.pointsText,
    super.percentage,
    super.userName,
    super.avatarUrl,
    super.subtitle,
    super.rank,
    super.hasData,
  });

  factory HighlightCardModel.fromJson(Map<String, dynamic> json) {
    return HighlightCardModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      pointsText: json['pointsText']?.toString(),
      percentage: (json['percentage'] as num?) ?? 0,
      userName: json['userName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      subtitle: json['subtitle']?.toString(),
      rank: (json['rank'] as num?)?.toInt(),
      hasData: json['hasData'] != false,
    );
  }
}
