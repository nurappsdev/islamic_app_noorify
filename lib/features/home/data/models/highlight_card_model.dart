import 'package:islami_app_noorify/core/utils/localized_text.dart';
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
    super.localizedTitle,
    super.localizedSubtitle,
    super.localizedPointsText,
    super.localizedPercentage,
    super.localizedRank,
  });

  factory HighlightCardModel.fromJson(Map<String, dynamic> json) {
    final localized = json['localized'];
    final localizedJson = localized is Map
        ? localized
        : const <String, dynamic>{};
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
      localizedTitle: LocalizedText.fromJson(localizedJson['title']),
      localizedSubtitle: LocalizedText.fromJson(localizedJson['subtitle']),
      localizedPointsText: LocalizedText.fromJson(localizedJson['pointsText']),
      localizedPercentage: LocalizedText.fromJson(localizedJson['percentage']),
      localizedRank: LocalizedText.fromJson(localizedJson['rank']),
    );
  }
}
