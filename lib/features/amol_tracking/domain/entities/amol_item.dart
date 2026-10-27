import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_entry.dart';

/// One checklist item inside an [AmolPillar] (e.g. Fajr inside Fardh Prayer).
///
/// The server's per-option breakdown ("In jama'at" / "After jama'at, alone" /
/// "Kaja") isn't modeled here — the app only displays the resulting
/// [isCompleted] state and the [points] already earned for the day.
class AmolItem {
  const AmolItem({
    required this.itemKey,
    required this.title,
    required this.titleBn,
    required this.points,
    required this.maxPoints,
    required this.isCompleted,
    this.entry,
  });

  final String itemKey;
  final String title;
  final String titleBn;
  final num points;
  final num maxPoints;
  final bool isCompleted;

  /// How much has been tracked today, for an item measured by amount
  /// (minutes read, zikr counted). `null` for a plain tick-mark item.
  final AmolEntry? entry;

  AmolItem copyWith({num? points, bool? isCompleted, AmolEntry? entry}) =>
      AmolItem(
        itemKey: itemKey,
        title: title,
        titleBn: titleBn,
        points: points ?? this.points,
        maxPoints: maxPoints,
        isCompleted: isCompleted ?? this.isCompleted,
        entry: entry ?? this.entry,
      );
}
