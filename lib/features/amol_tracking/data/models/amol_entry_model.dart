import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_entry.dart';

class AmolEntryModel extends AmolEntry {
  const AmolEntryModel({
    required super.unit,
    required super.entrySize,
    required super.entryPoints,
    required super.maxEntries,
    required super.entries,
    required super.amount,
    required super.targetAmount,
    super.unitLabel,
  });

  /// The `entry` object of one item, or `null` for a plain tick-mark item
  /// (which has no such block).
  static AmolEntryModel? tryParse(Object? json) {
    if (json is! Map) return null;
    int count(Object? value) => (value as num?)?.round() ?? 0;
    return AmolEntryModel(
      unit: json['unit']?.toString() ?? '',
      entrySize: (json['entrySize'] as num?) ?? 0,
      entryPoints: (json['entryPoints'] as num?) ?? 0,
      maxEntries: count(json['maxEntries']),
      entries: count(json['entries']),
      amount: (json['amount'] as num?) ?? 0,
      targetAmount: (json['targetAmount'] as num?) ?? 0,
      unitLabel: LocalizedText.fromJson({
        'en': json['unitLabel'],
        'bn': json['unitLabelBn'],
      }),
    );
  }
}
