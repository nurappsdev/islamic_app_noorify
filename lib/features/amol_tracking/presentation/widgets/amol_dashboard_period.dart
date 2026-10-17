import 'package:tuhfatul_muslim/core/utils/app_text.dart';

enum AmolPeriod { daily, weekly, monthly }

/// `pillarKey` order the chart's x-axis renders in for daily/weekly —
/// matches `GET /amol/tracker/daily`'s pillars and the fixed category
/// label list. `tasbih` is the server key for the Zikr pillar (not `zikr`).
/// Monthly ignores this and uses the server's own `pillars` list instead
/// (see `AmolDashboardViewModel`).
const kAmolPillarOrder = [
  'fardh_prayer',
  'sunnah_witr',
  'quran',
  'nafl_salat',
  'hadith',
  'quiz',
  'tasbih',
  'dua',
  'nafl_and_more',
];

extension AmolPeriodX on AmolPeriod {
  String label(AppText appText) => switch (this) {
    AmolPeriod.daily => appText.daily,
    AmolPeriod.weekly => appText.weekly,
    AmolPeriod.monthly => appText.monthly,
  };

  // Matches the bloc's `_windowDaysByPeriod` sliding-window lengths, so
  // stepping the date navigator lines up with what each request actually
  // resolves to server-side.
  Duration get step => switch (this) {
    AmolPeriod.daily => const Duration(days: 1),
    AmolPeriod.weekly => const Duration(days: 7),
    AmolPeriod.monthly => const Duration(days: 33),
  };

  /// Overrides `AmolSummaryCard`'s default title — `null` (daily) keeps
  /// its own default ("Todays Amol Track").
  String? summaryCardTitle(AppText appText) => switch (this) {
    AmolPeriod.daily => null,
    AmolPeriod.weekly => appText.weeklyAmolTrack,
    AmolPeriod.monthly => appText.monthlyAmolTrack,
  };
}
