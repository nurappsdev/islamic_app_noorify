import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

/// The `entry` block `GET /amol/tracker/daily` sends with an entry item
/// (Quran, Hadis and Dua minutes; Tasbih zikr counts; Quiz attempts).
///
/// Points come one [entryPoints] at a time for every whole [entrySize] of
/// [amount] tracked, [maxEntries] at most: Quran awards one point per five
/// minutes read, nine at most (45 minutes), Hadis 0.75 per five minutes.
/// The pillar's own `formattedSubtext` is a points fraction (`"5/9"`), so
/// this block is the only place the day's tracked *amount* is reported.
class AmolEntry {
  const AmolEntry({
    required this.unit,
    required this.entrySize,
    required this.entryPoints,
    required this.maxEntries,
    required this.entries,
    required this.amount,
    required this.targetAmount,
    this.unitLabel = LocalizedText.empty,
  });

  /// `minutes` for the reading pillars, `count` for Tasbih's zikr.
  final String unit;

  /// How much one entry is worth (e.g. 5 minutes).
  final num entrySize;

  /// The points one entry earns.
  final num entryPoints;
  final int maxEntries;
  final int entries;

  /// Tracked so far today, in [unit] (minutes read, zikr counted).
  final num amount;

  /// The amount that earns the item's full points.
  final num targetAmount;

  /// `count` units name themselves ("zikr"); minutes don't.
  final LocalizedText unitLabel;

  bool get isMinutes => unit == 'minutes';

  /// The whole entries [value] is worth, never beyond [maxEntries].
  int entriesFor(num value) {
    if (entrySize <= 0 || value <= 0) return 0;
    final whole = (value / entrySize).floor();
    return whole > maxEntries ? maxEntries : whole;
  }

  /// The points [value] earns under this item's own rule.
  num pointsFor(num value) => entriesFor(value) * entryPoints;

  /// The same rule with [value] tracked instead. Used when the device has
  /// reading the server hasn't accepted yet, and to empty a new day's
  /// template ([withAmount] of `0`).
  AmolEntry withAmount(num value) => AmolEntry(
    unit: unit,
    entrySize: entrySize,
    entryPoints: entryPoints,
    maxEntries: maxEntries,
    entries: entriesFor(value),
    amount: value < 0 ? 0 : value,
    targetAmount: targetAmount,
    unitLabel: unitLabel,
  );
}
