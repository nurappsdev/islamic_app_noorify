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
}
