import 'dart:math' as math;

import 'package:tuhfatul_muslim/features/amol_tracking/presentation/bloc/amol_dashboard_bloc.dart';
import 'amol_dashboard_period.dart';

String formatAmolScoreValue(num value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

/// The competitor bubble is a small pill, so a full server-given name (e.g.
/// "Abdullah Al Masud") is shortened to its first two characters (e.g. "Ab")
/// to fit it — never the full name.
String amolInitials(String name, {required String fallback}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return fallback;
  return trimmed.substring(0, trimmed.length < 2 ? trimmed.length : 2);
}

/// The current calendar month plus the 11 before it, newest first, for the
/// monthly tab's month-picker dropdown.
List<DateTime> lastTwelveAmolMonths(DateTime today) => [
  for (var i = 0; i < 12; i++) DateTime(today.year, today.month - i),
];

/// The requested window's start date, mirroring the bloc's own calculation
/// — used only as a label fallback before the server's `range` has loaded.
DateTime startOfAmolWindow(AmolPeriod period, AmolDashboardState state) {
  if (state.rangeStart != null) return state.rangeStart!;
  return state.date.subtract(period.step - const Duration(days: 1));
}

bool isSameAmolDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Weekly/monthly bar charts only: a clean, human-readable y-axis built
/// entirely from the values actually on screen — e.g. `[0, 50, 100, 150,
/// 200, 250, 300]` when the highest score shown is 300 — instead of a
/// fixed division of some external ceiling. Every bar's height is then a
/// mathematically exact ratio against this same axis for every column, so
/// 10 vs. 300 reads on screen exactly as dramatic a gap as it is in real
/// points; the axis simply grows or shrinks to whatever the current data
/// actually needs, at 10, 300, 1000, or any other magnitude.
///
/// Mirrors the classic "nice numbers for graph labels" algorithm
/// (Heckbert): pick a round step from `{1, 2, 5} × 10ⁿ` close to
/// `highest / targetIntervals`, then the axis max is the smallest
/// multiple of that step at or above the highest value.
List<double> niceAmolAxisTicks(
  List<double> values,
  List<double?> competitorValues,
) {
  var highest = 0.0;
  for (final value in values) {
    if (value > highest) highest = value;
  }
  for (final value in competitorValues) {
    if (value != null && value > highest) highest = value;
  }
  // No data at all (e.g. everyone's at 0 this window) still needs a
  // non-zero axis to divide into readable steps.
  if (highest <= 0) highest = 4;
  const targetIntervals = 5;
  final step = niceAmolStep(highest / targetIntervals);
  final tickCount = (highest / step).ceil();
  return [for (var i = 0; i <= tickCount; i++) i * step];
}

/// Rounds [value] to the nearest "nice" leading digit (1, 2 or 5) at its
/// own order of magnitude — e.g. 83 -> 100, 42 -> 50, 18 -> 20 — the
/// standard building block for human-friendly axis steps.
double niceAmolStep(double value) {
  if (value <= 0) return 1;
  final exponent = (math.log(value) / math.ln10).floor();
  final magnitude = math.pow(10, exponent).toDouble();
  final fraction = value / magnitude;
  final niceFraction = fraction < 1.5
      ? 1
      : fraction < 3
      ? 2
      : fraction < 7
      ? 5
      : 10;
  return niceFraction * magnitude;
}
