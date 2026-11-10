import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_entry.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_item.dart';

/// One deed-pillar's daily checklist (Fardh Prayer, Quran, ...) from
/// `GET /amol/tracker/daily`.
class AmolPillar {
  const AmolPillar({
    required this.pillarKey,
    required this.title,
    required this.titleBn,
    required this.earnedPoints,
    required this.maxPoints,
    required this.percentage,
    required this.formattedSubtext,
    required this.items,
  });

  final String pillarKey;
  final String title;
  final String titleBn;
  final num earnedPoints;
  final num maxPoints;
  final num percentage;

  /// Server-formatted progress text (e.g. `"2/7"`). It is a points fraction
  /// for every pillar, entry pillars included — the amount they track
  /// (minutes read, zikr counted) is reported in [entry] instead.
  final String formattedSubtext;
  final List<AmolItem> items;

  /// The amount tracked for a pillar measured by one amount (Quran, Hadis
  /// and Dua minutes). A multi-item pillar (Tasbih's five zikrs) keeps an
  /// amount per item, and a tick-mark pillar has none, so both give `null`.
  AmolEntry? get entry => items.length == 1 ? items.single.entry : null;

  AmolPillar copyWith({
    num? earnedPoints,
    num? percentage,
    String? formattedSubtext,
    List<AmolItem>? items,
  }) => AmolPillar(
    pillarKey: pillarKey,
    title: title,
    titleBn: titleBn,
    earnedPoints: earnedPoints ?? this.earnedPoints,
    maxPoints: maxPoints,
    percentage: percentage ?? this.percentage,
    formattedSubtext: formattedSubtext ?? this.formattedSubtext,
    items: items ?? this.items,
  );
}
