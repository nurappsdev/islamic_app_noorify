/// One deed-pillar's daily progress (Fardh Prayer, Quran, Zikr, ...) from
/// the Home dashboard's `pillarCards`.
class PillarCard {
  const PillarCard({
    required this.pillarKey,
    required this.title,
    required this.points,
    required this.maxPoints,
    required this.percentage,
    required this.formattedSubtext,
  });

  /// Stable identifier, e.g. `fardh_prayer`, `quran`, `nafl_and_more`.
  final String pillarKey;

  /// Server-provided English title; only used as a fallback since the app
  /// localizes known [pillarKey]s itself.
  final String title;

  final num points;
  final num maxPoints;
  final num percentage;

  /// Server-formatted progress text (e.g. `"0/7"`, `"1hr 37min"`).
  final String formattedSubtext;
}
