import 'dart:math' as math;

import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_dashboard.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_history.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_points.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_progress.dart';

/// Applies device-only reading time to a server response. The source reports
/// remain separate and idempotent; this only makes an already-open screen
/// reflect them before its next API response arrives.
QuranDailyProgress projectQuranDailyReading(
  QuranDailyProgress day, {
  required int additionalSeconds,
}) {
  if (additionalSeconds <= 0) return day;
  final readSeconds = day.readSeconds + additionalSeconds;
  // Keep duration and points inseparable while local reading is overlaid.
  // Carrying a stale server point value forward would allow an impossible
  // state such as 14 minutes paired with four five-minute points.
  final double points = math.min(
    quranReadingPointsForSeconds(readSeconds).toDouble(),
    day.maxPoints,
  );
  final addedPoints = points - day.points;
  final remainingSeconds = math.max(day.goalSeconds - readSeconds, 0);
  final percentage = day.goalSeconds <= 0
      ? day.percentage
      : ((readSeconds / day.goalSeconds) * 100).clamp(0, 100).round();
  return day.copyWith(
    readSeconds: readSeconds,
    // The existing UI is minute based; do not introduce second fractions.
    readMinutes: (readSeconds ~/ 60).toDouble(),
    remainingSeconds: remainingSeconds,
    remainingMinutes: (remainingSeconds ~/ 60).toDouble(),
    points: points,
    percentage: percentage,
    isGoalMet: day.goalSeconds > 0 && readSeconds >= day.goalSeconds,
    pointsText: _replaceLeadingNumber(day.pointsText, points),
    progressText: _replaceLeadingNumber(
      day.progressText,
      (readSeconds ~/ 60).toDouble(),
    ),
    dailyTotalPoints: day.dailyTotalPoints == null
        ? null
        : day.dailyTotalPoints! + addedPoints,
  );
}

/// Projects each dated report into an API history response.
QuranReadingHistory projectQuranReadingHistory(
  QuranReadingHistory history,
  int Function(DateTime date) additionalSecondsForDate,
) {
  var addedSeconds = 0;
  var addedPoints = 0.0;
  var addedGoalDays = 0;
  final days = <QuranDailyProgress>[];
  for (final day in history.days) {
    final date = day.date;
    if (date == null) {
      days.add(day);
      continue;
    }
    final projected = projectQuranDailyReading(
      day,
      additionalSeconds: additionalSecondsForDate(date),
    );
    addedSeconds += projected.readSeconds - day.readSeconds;
    addedPoints += projected.points - day.points;
    if (!day.isGoalMet && projected.isGoalMet) addedGoalDays++;
    days.add(projected);
  }
  if (addedSeconds == 0) return history;
  final totals = history.totals;
  final totalSeconds = totals.totalSeconds + addedSeconds;
  return history.copyWith(
    days: days,
    totals: totals.copyWith(
      totalSeconds: totalSeconds,
      totalMinutes: (totalSeconds ~/ 60).toDouble(),
      totalPoints: totals.totalPoints + addedPoints,
      daysGoalMet: totals.daysGoalMet + addedGoalDays,
      averageMinutesPerDay: history.days.isEmpty
          ? totals.averageMinutesPerDay
          : (totalSeconds ~/ 60) / history.days.length,
    ),
  );
}

QuranReadingDashboard projectQuranReadingDashboard(
  QuranReadingDashboard dashboard,
  int Function(DateTime date) additionalSecondsForDate,
) {
  final today = dashboard.today.date;
  return dashboard.copyWith(
    today: today == null
        ? dashboard.today
        : projectQuranDailyReading(
            dashboard.today,
            additionalSeconds: additionalSecondsForDate(today),
          ),
    week: projectQuranReadingHistory(dashboard.week, additionalSecondsForDate),
  );
}

String _replaceLeadingNumber(String text, double value) {
  final match = RegExp(r'^(.*?)(\d+(?:\.\d+)?)(\s*/\s*.*)$').firstMatch(text);
  if (match == null) return text;
  final formatted = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
  return '${match.group(1)}$formatted${match.group(3)}';
}
