import 'package:islami_app_noorify/core/utils/localized_text.dart';

/// One card from the Home dashboard's `topHighlightCards` carousel
/// (today's amol, today's/yesterday's leaders, monthly rankings, ...).
class HighlightCard {
  const HighlightCard({
    required this.id,
    required this.type,
    required this.title,
    this.pointsText,
    this.percentage = 0,
    this.userName,
    this.avatarUrl,
    this.subtitle,
    this.rank,
    this.hasData = true,
    this.localizedTitle = LocalizedText.empty,
    this.localizedSubtitle = LocalizedText.empty,
    this.localizedPointsText = LocalizedText.empty,
    this.localizedPercentage = LocalizedText.empty,
    this.localizedRank = LocalizedText.empty,
  });

  final String id;

  /// Stable identifier used to pick the right (localized) label and layout,
  /// e.g. `todays_amol`, `monthly_first`, `my_monthly_position`.
  final String type;

  /// Server-provided English title; only used as a fallback for unknown
  /// [type]s since the app localizes known ones itself.
  final String title;

  final String? pointsText;
  final num percentage;
  final String? userName;
  final String? avatarUrl;
  final String? subtitle;
  final int? rank;

  /// `false` when the API has nothing to show for this card yet (e.g. no
  /// winner last month); the carousel skips such cards.
  final bool hasData;

  final LocalizedText localizedTitle;
  final LocalizedText localizedSubtitle;
  final LocalizedText localizedPointsText;
  final LocalizedText localizedPercentage;
  final LocalizedText localizedRank;
}
