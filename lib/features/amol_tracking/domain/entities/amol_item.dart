/// One checklist item inside an [AmolPillar] (e.g. Fajr inside Fardh Prayer).
///
/// The server's per-option breakdown ("In jama'at" / "After jama'at, alone" /
/// "Kaja") isn't modeled here — the app only displays the resulting
/// [isCompleted] state and the [points] already earned for the day.
class AmolItem {
  const AmolItem({
    required this.itemKey,
    required this.title,
    required this.points,
    required this.maxPoints,
    required this.isCompleted,
  });

  final String itemKey;
  final String title;
  final num points;
  final num maxPoints;
  final bool isCompleted;
}
