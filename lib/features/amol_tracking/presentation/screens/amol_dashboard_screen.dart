import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/datasources/amol_analytics_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/repositories/amol_analytics_repository_impl.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_analytics_point.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/get_amol_analytics_graph.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/bloc/amol_dashboard_bloc.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_localized_format.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_shared_widgets.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_context.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

enum _AmolPeriod { daily, weekly, monthly }

/// `pillarKey` order the chart's x-axis renders in — matches
/// `GET /amol/tracker/daily`'s pillars and the `categories` list below.
const _pillarOrder = [
  'fardh_prayer',
  'sunnah_witr',
  'quran',
  'nafl_salat',
  'hadith',
  'quiz',
  'nafl_and_more',
];

String _formatPoints(num value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

/// The competitor bubble is a small pill, so a full server-given name (e.g.
/// "Khalid Saifullah") is shortened to initials (e.g. "KS") to fit it.
String _initials(String name, {required String fallback}) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final letters = words.map((w) => w[0].toUpperCase()).take(2).join();
  return letters.isEmpty ? fallback : letters;
}

/// The current calendar month plus the 11 before it, newest first, for the
/// monthly tab's month-picker dropdown.
List<DateTime> _lastTwelveMonths(DateTime today) => [
  for (var i = 0; i < 12; i++) DateTime(today.year, today.month - i),
];

/// The requested window's start date, mirroring the bloc's own calculation
/// — used only as a label fallback before the server's `range` has loaded.
DateTime _startOfWindow(_AmolPeriod period, AmolDashboardState state) {
  if (state.rangeStart != null) return state.rangeStart!;
  return state.date.subtract(period.step - const Duration(days: 1));
}

bool _isSameDate(DateTime a, DateTime b) =>
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
List<double> _niceAxisTicks(List<double> values, List<double?> competitorValues) {
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
  final step = _niceStep(highest / targetIntervals);
  final tickCount = (highest / step).ceil();
  return [for (var i = 0; i <= tickCount; i++) i * step];
}

/// Rounds [value] to the nearest "nice" leading digit (1, 2 or 5) at its
/// own order of magnitude — e.g. 83 -> 100, 42 -> 50, 18 -> 20 — the
/// standard building block for human-friendly axis steps.
double _niceStep(double value) {
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

extension on _AmolPeriod {
  String label(AppText appText) => switch (this) {
    _AmolPeriod.daily => appText.daily,
    _AmolPeriod.weekly => appText.weekly,
    _AmolPeriod.monthly => appText.monthly,
  };

  // Matches the bloc's `_windowDaysByPeriod` sliding-window lengths, so
  // stepping the date navigator lines up with what each request actually
  // resolves to server-side.
  Duration get step => switch (this) {
    _AmolPeriod.daily => const Duration(days: 1),
    _AmolPeriod.weekly => const Duration(days: 7),
    _AmolPeriod.monthly => const Duration(days: 33),
  };
}

class AmolDashboardScreen extends StatelessWidget {
  const AmolDashboardScreen({super.key, this.now});

  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AmolDashboardBloc(
        GetAmolAnalyticsGraph(
          AmolAnalyticsRepositoryImpl(AmolAnalyticsRemoteDataSourceImpl()),
        ),
        now: now,
      )..add(const LoadGraph()),
      child: const _AmolDashboardView(),
    );
  }
}

class _AmolDashboardView extends StatelessWidget {
  const _AmolDashboardView();

  // Shown before the first `GET /amol/analytics/graph` response lands.
  static const _fallbackMyPosition = [6.0, 10.0, 2.0, 9.0, 2.0, 10.0, 3.0];
  static const _fallbackCompetitorValues = [
    6.0,
    9.0,
    null,
    8.0,
    null,
    11.0,
    null,
  ];
  static const _fallbackPoints = 27;
  static const _fallbackTotalPoints = 40;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AmolDashboardBloc>().state;
    final bloc = context.read<AmolDashboardBloc>();
    final appText = AppText.of(context);
    final period = _AmolPeriod.values[state.selectedPeriod];
    final categories = [
      appText.categoryFardhPrayer,
      appText.categorySunnahAndWitr,
      appText.categoryQuran,
      appText.categoryNaflSalat,
      appText.categoryHadith,
      appText.categoryQuiz,
      appText.categoryNaflAndMore,
    ];
    final graph = state.graph;
    final values = graph == null
        ? _fallbackMyPosition
        : [for (final key in _pillarOrder) graph.valueFor(key).toDouble()];
    final competitorValues = graph == null
        ? _fallbackCompetitorValues
        : [
            for (final key in _pillarOrder)
              graph.competitorValueFor(key)?.toDouble(),
          ];
    final competitorLabel = graph == null
        ? appText.competitorInitials
        : _initials(graph.competitorName, fallback: appText.competitorInitials);
    // The signed-in device's own name (set on the profile screen), not
    // anything from the server response — mirrors the competitor's pill
    // but labeled with the local user's initials instead.
    final myLabel = _initials(
      profileNameNotifier.value ?? appText.competitorName,
      fallback: languageOf(context) == AppLanguage.bangla ? 'আমি' : 'Me',
    );
    // Use the server's summary totals and percentage, then format the visible
    // point label in the selected language.
    final summary = graph?.summary;
    final myPoints = graph == null
        ? _fallbackPoints
        : (summary?.totalEarnedPoints ?? graph.myTotalPoints).round();
    final totalPoints = graph == null
        ? _fallbackTotalPoints
        : (summary?.totalPossiblePoints ?? graph.maxTotalPoints).round();
    final pointLabel = graph == null
        ? formatAmolPoints(30, 40, appText, languageOf(context))
        : formatAmolPoints(
            summary?.totalEarnedPoints ?? graph.myTotalPoints,
            summary?.totalPossiblePoints ?? graph.maxTotalPoints,
            appText,
            languageOf(context),
          );
    final percentValue = graph == null
        ? 86.0
        : (summary?.percentage ??
                  graph.serverCompletionPercentage ??
                  graph.completionPercentage)
              .toDouble();
    final progress = (percentValue / 100).clamp(0.0, 1.0);
    final progressLabel = context.localizedDigits('${percentValue.round()} %');
    final maxY = graph == null ? 12.0 : graph.yAxisMax.toDouble();
    // Prefer the server's own resolved range (it's the ground truth for
    // exactly which days the response covers) over a locally-guessed
    // label; only fall back to local formatting before the first response
    // lands.
    // Format the server's resolved ISO dates with local month names and digits.
    final resolvedRange = graph?.range;
    final localizedRange = resolvedRange == null
        ? ''
        : formatAmolRange(
            resolvedRange.startDate,
            resolvedRange.endDate,
            appText,
            languageOf(context),
          );
    final rangeLabel = localizedRange.isNotEmpty
        ? localizedRange
        : context.localizedDigits(
            period == _AmolPeriod.daily
                ? formatAmolDate(state.date, appText)
                : '${formatAmolDate(_startOfWindow(period, state), appText)} - ${formatAmolDate(state.date, appText)}',
          );
    // Monthly shows the same real per-pillar categories as daily/weekly,
    // but reads them straight off the loaded graph's own `pillars` instead
    // of the fixed `_pillarOrder`/`categories` above — so any category the
    // server actually returns (e.g. one this hardcoded list doesn't cover)
    // still shows up, instead of being silently dropped.
    final monthlyPillars = graph?.pillars ?? const <AmolAnalyticsPoint>[];
    final isBangla = languageOf(context) == AppLanguage.bangla;
    final showMonthlyPillars = period == _AmolPeriod.monthly && graph != null;
    final chartCategories = showMonthlyPillars
        ? [
            for (final pillar in monthlyPillars)
              (isBangla && pillar.titleBn.isNotEmpty)
                  ? pillar.titleBn
                  : pillar.title,
          ]
        : categories;
    final chartValues = showMonthlyPillars
        ? [for (final pillar in monthlyPillars) pillar.myScore.toDouble()]
        : values;
    final chartCompetitorValues = showMonthlyPillars
        ? [
            for (final pillar in monthlyPillars)
              pillar.competitorScore?.toDouble(),
          ]
        : competitorValues;
    // Weekly/monthly bars compute their own fully data-driven y-axis (see
    // `_niceAxisTicks`) instead of using the server's `maxY`. Daily keeps
    // the server's `maxY` as-is.
    final isColumnLayout = period == _AmolPeriod.weekly || showMonthlyPillars;
    final navigation = graph?.navigation;
    // Whether stepping "next" would go anywhere: computed locally rather
    // than trusted from the server's `navigation.hasNext` — that field
    // wasn't reliably flipping true again after navigating back with
    // "previous" (across daily/weekly/monthly alike, including daily,
    // which never even sends an `offset`), permanently disabling the next
    // arrow. Since [ShiftDate] already clamps forward movement to never
    // pass today, whether "next" has anywhere to go is fully known
    // locally: yes, whenever the viewed date isn't already today.
    final hasNext = !_isSameDate(state.date, state.today);
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            AmolHeader(title: appText.amolTracking),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 20.h),
                children: [
                  _PeriodTabs(
                    period: period,
                    onChanged: (value) => bloc.add(SelectPeriod(value.index)),
                  ),
                  SizedBox(height: 16.h),
                  AmolSummaryCard(
                    title: switch (period) {
                      _AmolPeriod.daily => null,
                      _AmolPeriod.weekly => appText.weeklyAmolTrack,
                      _AmolPeriod.monthly => appText.monthlyAmolTrack,
                    },
                    pointLabel: pointLabel,
                    progressLabel: progressLabel,
                    progress: progress,
                  ),
                  SizedBox(height: 14.h),
                  _DateNavigator(
                    label: rangeLabel,
                    subtitle: '${period.label(appText)} ${appText.amolTrack}',
                    onPrevious: navigation == null || navigation.hasPrevious
                        ? () => bloc.add(ShiftDate(period.step, -1))
                        : null,
                    onNext: hasNext
                        ? () => bloc.add(ShiftDate(period.step, 1))
                        : null,
                  ),
                  if (period == _AmolPeriod.monthly) ...[
                    SizedBox(height: 10.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _MonthDropdown(
                        selectedMonth: DateTime(
                          state.date.year,
                          state.date.month,
                        ),
                        months: _lastTwelveMonths(state.today),
                        appText: appText,
                        onChanged: (month) => bloc.add(SelectMonth(month)),
                      ),
                    ),
                  ],
                  SizedBox(height: 18.h),
                  RichText(
                    // Daily keeps its existing two-part caption unchanged;
                    // weekly/monthly have no analogous "average todays
                    // days" clause, so they show just the corrected
                    // heading ("This Week's"/"This Month's Average") in
                    // the same bold-italic style as daily's "Todays".
                    text: period == _AmolPeriod.daily
                        ? TextSpan(
                            children: [
                              TextSpan(
                                text: appText.todays,
                                style: TextStyle(
                                  color: context.inkColor(Colors.black),
                                  fontSize: 15.sp,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: ' ${appText.averageTodaysDays}',
                                style: TextStyle(
                                  color: context.inkColor(Colors.black87),
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          )
                        : TextSpan(
                            text: period == _AmolPeriod.weekly
                                ? appText.thisWeeksAverage
                                : appText.thisMonthsAverage,
                            style: TextStyle(
                              color: context.inkColor(Colors.black),
                              fontSize: 15.sp,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  SizedBox(height: 12.h),
                  const _Legend(),
                  SizedBox(height: 10.h),
                  if (showMonthlyPillars && monthlyPillars.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: Center(
                        child: Text(
                          appText.noResultsFound,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: context.inkColor(const Color(0xFF5D6B44)),
                          ),
                        ),
                      ),
                    )
                  else
                    _AmolLineChart(
                      categories: chartCategories,
                      values: chartValues,
                      myLabel: myLabel,
                      competitorValues: chartCompetitorValues,
                      competitorLabel: competitorLabel,
                      maxY: maxY,
                      // Weekly mirrors the Hadith dashboard's weekly tab:
                      // the same per-pillar data, drawn as columns instead
                      // of a line. Monthly uses every real category (not
                      // just the fixed list above) with vertical, scrollable
                      // labels; tapping a column shows the same my/competitor
                      // points tooltip weekly uses. Daily keeps the existing
                      // line chart.
                      columnLayout: isColumnLayout,
                      verticalLabels: showMonthlyPillars,
                      // Weekly's fixed 7-category list (including Nafl
                      // Salat and Nafl And More, the last two) can run off
                      // the screen edge with diagonal labels on a narrow
                      // device — scrollable horizontally, same as monthly,
                      // so every category stays reachable by swiping.
                      scrollable: isColumnLayout,
                    ),
                  SizedBox(height: 18.h),
                  _MyPointsBar(myPoints: myPoints, totalPoints: totalPoints),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.period, required this.onChanged});

  final _AmolPeriod period;
  final ValueChanged<_AmolPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFF3F4EA)),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        children: [
          for (final value in _AmolPeriod.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(vertical: 9.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.surfaceColor(
                      value == period
                          ? const Color(0xFFCBD79A)
                          : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    value.label(appText),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: value == period
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: context.inkColor(
                        value == period
                            ? const Color(0xFF3F4A32)
                            : const Color(0xFF9AA48A),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.label,
    required this.subtitle,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final String subtitle;

  /// `null` disables the arrow — the server said there's nothing further
  /// that way (`navigation.hasPrevious`/`hasNext`).
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: context.lineColor(Color(0xFFDCE9B8))),
      ),
      child: Row(
        children: [
          _NavArrow(icon: Icons.chevron_left, onTap: onPrevious),
          Expanded(
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: context.inkColor(Colors.black),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: context.inkColor(Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          _NavArrow(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

/// Lets the user jump the monthly tab straight to one of the last 12
/// calendar months (e.g. "August 2026"), instead of stepping 30 days at a
/// time via [_DateNavigator]'s arrows.
class _MonthDropdown extends StatelessWidget {
  const _MonthDropdown({
    required this.selectedMonth,
    required this.months,
    required this.appText,
    required this.onChanged,
  });

  final DateTime selectedMonth;
  final List<DateTime> months;
  final AppText appText;
  final ValueChanged<DateTime> onChanged;

  String _label(BuildContext context, DateTime month) => context
      .localizedDigits('${appText.monthNames[month.month - 1]} ${month.year}');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: context.lineColor(Color(0xFFDCE9B8))),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateTime>(
          // Falls back to a hint (rather than asserting) when the current
          // selection isn't one of the last 12 months, e.g. after stepping
          // further back with the date-navigator arrows.
          value: months.contains(selectedMonth) ? selectedMonth : null,
          hint: Text(
            _label(context, selectedMonth),
            style: TextStyle(
              fontSize: 13.sp,
              color: context.inkColor(Colors.black),
            ),
          ),
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.inkColor(Color(0xFF7E8C61)),
            size: 18.sp,
          ),
          borderRadius: BorderRadius.circular(16.r),
          dropdownColor: context.surfaceColor(Colors.white),
          style: TextStyle(
            fontSize: 13.sp,
            color: context.inkColor(Colors.black),
          ),
          items: [
            for (final month in months)
              DropdownMenuItem(
                value: month,
                child: Text(_label(context, month)),
              ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox.square(
      dimension: 32.r,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: context.surfaceColor(
            enabled ? Colors.white : const Color(0xFFF2F3EA),
          ),
          side: BorderSide(color: context.lineColor(Color(0xFFDCE9B8))),
        ),
        icon: Icon(
          icon,
          size: 16.sp,
          color: context.inkColor(
            enabled ? const Color(0xFF7E8C61) : const Color(0xFFC5CAB8),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Row(
      children: [
        _LegendDot(
          color: _LineChartPainter.lineColor,
          label: appText.myPosition,
        ),
        SizedBox(width: 18.w),
        _LegendDot(
          color: _LineChartPainter.competitorLineColor,
          label: appText.myNearestOrCompetitor,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9.r,
          height: 9.r,
          decoration: BoxDecoration(
            color: context.surfaceColor(color),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: context.inkColor(Colors.black87),
          ),
        ),
      ],
    );
  }
}

class _AmolLineChart extends StatefulWidget {
  const _AmolLineChart({
    required this.categories,
    required this.values,
    required this.myLabel,
    required this.competitorValues,
    required this.competitorLabel,
    required this.maxY,
    required this.columnLayout,
    this.verticalLabels = false,
    this.scrollable = false,
  });

  final List<String> categories;
  final List<double> values;

  /// The local signed-in user's initials, shown on a pill at each of
  /// [values]'s points (mirrors [competitorLabel]'s pill).
  final String myLabel;

  /// The nearest competitor's score per category, `null` where the server
  /// has none for that pillar (no bubble is drawn there).
  final List<double?> competitorValues;
  final String competitorLabel;
  final double maxY;

  /// True for the weekly and monthly tabs: draws the same per-pillar
  /// points as overlapping columns ([_BarChartPainter]) instead of a
  /// connected line ([_LineChartPainter]), matching the Hadith dashboard's
  /// weekly bar chart. Everything else (grid, axis labels, score bubbles,
  /// tap-to-select tooltip) is shared and unaffected by this flag.
  final bool columnLayout;

  /// Monthly's vertical category labels instead of daily/weekly's diagonal
  /// ones (reference image). Only meaningful together with [columnLayout].
  final bool verticalLabels;

  /// Wraps the chart in horizontal scrolling and widens it to fit every
  /// category at a readable column width, instead of squeezing them all
  /// into the viewport. Monthly only — it can have more categories than
  /// daily/weekly's fixed 7-pillar list ever does.
  final bool scrollable;

  @override
  State<_AmolLineChart> createState() => _AmolLineChartState();
}

class _AmolLineChartState extends State<_AmolLineChart> {
  /// Which category column is showing its tap tooltip; `null` when none is.
  int? _selectedIndex;

  void _select(int index) {
    setState(() => _selectedIndex = _selectedIndex == index ? null : index);
  }

  /// The widest category label at the chart's label font size — monthly's
  /// vertical labels need the bottom plot margin sized to this (rotated 90°,
  /// a label's width becomes its vertical extent), so nothing is truncated
  /// regardless of how long a category's name is.
  static double _verticalLabelExtent(List<String> categories) {
    var maxWidth = 0.0;
    for (final category in categories) {
      final painter = TextPainter(
        text: TextSpan(
          text: category,
          style: TextStyle(fontSize: 9.sp),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (painter.width > maxWidth) maxWidth = painter.width;
    }
    return maxWidth;
  }

  /// The widest y-axis tick label at the chart's label font size — needed
  /// so the left gutter ([_AmolLineChartState.build]'s `plotLeft`) can
  /// grow enough to keep 4-digit-plus values (1,000+) fully on-screen
  /// instead of clipping against the chart's left edge.
  static double _tickLabelExtent(List<double> ticks, AppLanguage language) {
    var maxWidth = 0.0;
    for (final tick in ticks) {
      final painter = TextPainter(
        text: TextSpan(
          text: localizeDigits(tick.round().toString(), language),
          style: TextStyle(fontSize: 9.sp),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (painter.width > maxWidth) maxWidth = painter.width;
    }
    return maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    // Weekly/monthly bar charts get their own fully data-driven y-axis
    // (see `_niceAxisTicks`) instead of the line chart's fixed division
    // of `widget.maxY`; `tickValues.last` is then the bar chart's axis
    // ceiling everywhere it's needed (point scaling, grid, labels).
    final tickValues = widget.columnLayout
        ? _niceAxisTicks(widget.values, widget.competitorValues)
        : null;
    final axisMaxY = tickValues?.last ?? widget.maxY;
    final language = languageOf(context);
    // Grows past its normal width only when a tick label (e.g. "1,250")
    // genuinely needs the room, so small values look exactly as before.
    final plotLeft = tickValues == null
        ? 24.w
        : math.max(24.w, _tickLabelExtent(tickValues, language) + 10.w);
    final plotTop = 30.h;
    final plotRight = 6.w;
    final plotBottom = widget.verticalLabels
        ? _verticalLabelExtent(widget.categories) + 16.h
        : 48.h;
    // The plotted area always gets the same vertical room (the original
    // 240.h total, minus its 30.h top and 48.h bottom); only the label band
    // below it grows for monthly's taller vertical labels.
    final height = plotTop + 162.h + plotBottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final categoryCount = widget.categories.length;
        // Wide enough for each column's bar and vertical label to have
        // breathing room; scrolls past that instead of squeezing every
        // category into the viewport when there are many of them.
        final minColumnWidth = 56.w;
        final width = widget.scrollable
            ? math.max(constraints.maxWidth, categoryCount * minColumnWidth)
            : constraints.maxWidth;
        final plotRect = Rect.fromLTWH(
          plotLeft,
          plotTop,
          (width - plotLeft - plotRight).clamp(0.0, double.infinity),
          (height - plotTop - plotBottom).clamp(0.0, double.infinity),
        );
        final points = _computePoints(
          plotRect,
          widget.values,
          axisMaxY,
          slotted: widget.columnLayout,
        ).cast<Offset>();
        final competitorPoints = _computePoints(
          plotRect,
          widget.competitorValues,
          axisMaxY,
          slotted: widget.columnLayout,
        );
        // Mirrors `_computePoints`' own spacing for this layout, so the
        // tap zones below land exactly on the columns they're meant for.
        final stepX = widget.columnLayout
            ? (categoryCount > 0 ? plotRect.width / categoryCount : 0.0)
            : (categoryCount > 1
                  ? plotRect.width / (categoryCount - 1)
                  : plotRect.width);
        final selected = _selectedIndex;

        final chart = SizedBox(
          height: height,
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: widget.columnLayout
                    ? _BarChartPainter(
                        plotRect: plotRect,
                        categories: widget.categories,
                        points: points,
                        competitorPoints: competitorPoints,
                        tickValues: tickValues!,
                        language: language,
                        selectedIndex: selected,
                        verticalLabels: widget.verticalLabels,
                      )
                    : _LineChartPainter(
                        plotRect: plotRect,
                        categories: widget.categories,
                        points: points,
                        competitorPoints: competitorPoints,
                        maxY: widget.maxY,
                        language: language,
                        selectedIndex: selected,
                      ),
              ),
              // Tapping the empty chart background (outside any category's
              // column) dismisses the tooltip/highlight.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => setState(() => _selectedIndex = null),
                ),
              ),
              for (var i = 0; i < categoryCount; i++)
                Positioned(
                  // Centered on `points[i].dx` — the same x the bar/circle
                  // for this column actually renders at — rather than a
                  // separately re-derived formula that could (and once
                  // did) drift out of sync with it.
                  left: (points[i].dx - stepX / 2).clamp(0.0, width),
                  top: 0,
                  width: stepX,
                  height: plotRect.bottom,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _select(i),
                  ),
                ),
              for (var i = 0; i < competitorPoints.length; i++)
                if (competitorPoints[i] != null)
                  Positioned(
                    // Column layout (weekly/monthly): the circle sits at
                    // the bar's own top-left corner, i.e. exactly where
                    // that series' progress reaches — clamped the same way
                    // the painter clamps the bar's own left edge, so the
                    // two always land on the same pixel even for the
                    // first/last column. Line layout (daily) keeps its own
                    // point marker drawn by the painter, so the label
                    // floats just above it instead of covering it.
                    left: widget.columnLayout
                        ? (competitorPoints[i]!.dx -
                                  _BarChartPainter.barHalfWidth(
                                    categoryCount,
                                    plotRect.width,
                                  ))
                              .clamp(plotRect.left, plotRect.right)
                        : competitorPoints[i]!.dx,
                    top: widget.columnLayout
                        ? competitorPoints[i]!.dy.clamp(0.0, height)
                        : (competitorPoints[i]!.dy - 32.h).clamp(0.0, height),
                    child: FractionalTranslation(
                      translation: widget.columnLayout
                          ? const Offset(-0.5, -0.5)
                          : const Offset(-0.5, 0),
                      child: _ScoreBubble(
                        label: widget.competitorLabel,
                        pillColor: _LineChartPainter.competitorLineColor,
                        solid: widget.columnLayout,
                      ),
                    ),
                  ),
              for (var i = 0; i < points.length; i++)
                Positioned(
                  left: widget.columnLayout
                      ? (points[i].dx -
                                _BarChartPainter.barHalfWidth(
                                  categoryCount,
                                  plotRect.width,
                                ))
                            .clamp(plotRect.left, plotRect.right)
                      : points[i].dx,
                  top: widget.columnLayout
                      ? points[i].dy.clamp(0.0, height)
                      : (points[i].dy + 8.h).clamp(0.0, height),
                  child: FractionalTranslation(
                    translation: widget.columnLayout
                        ? const Offset(-0.5, -0.5)
                        : const Offset(-0.5, 0),
                    child: _ScoreBubble(
                      label: widget.myLabel,
                      pillColor: _LineChartPainter.lineColor,
                      solid: widget.columnLayout,
                    ),
                  ),
                ),
              // Tapping any column (daily/weekly/monthly alike) shows the
              // same my/competitor points tooltip.
              if (selected != null)
                Positioned(
                  left: points[selected].dx.clamp(
                    56.w,
                    (width - 56.w).clamp(56.w, double.infinity),
                  ),
                  top: _tooltipTop(points, competitorPoints, selected),
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0),
                    child: _ScoreTooltip(
                      title: widget.categories[selected],
                      myLabel: widget.myLabel,
                      myScore: widget.values[selected],
                      competitorLabel: widget.competitorLabel,
                      competitorScore: selected < widget.competitorValues.length
                          ? widget.competitorValues[selected]
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        );

        if (!widget.scrollable) return chart;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: chart,
        );
      },
    );
  }

  /// Anchors the tooltip just above whichever of the two lines is higher
  /// (smaller `dy`) at [index], so it never covers either marker.
  double _tooltipTop(
    List<Offset> points,
    List<Offset?> competitorPoints,
    int index,
  ) {
    final myY = index < points.length ? points[index].dy : double.infinity;
    final competitorY = index < competitorPoints.length
        ? competitorPoints[index]?.dy ?? double.infinity
        : double.infinity;
    final topY = myY < competitorY ? myY : competitorY;
    return (topY - 64.h).clamp(0.0, double.infinity);
  }

  /// Maps [values] onto [rect] using [maxY] as the y-axis ceiling. A `null`
  /// entry (only possible for competitor values) stays `null` in the
  /// result, so its bubble is skipped.
  ///
  /// [slotted] (bar charts, i.e. [_AmolLineChart.columnLayout]) divides
  /// [rect] into `values.length` equal slots and centers each point in its
  /// own slot, so the first/last bars get the same breathing room on both
  /// sides as every bar in between. Without it (the default, used by the
  /// line chart), the first and last points sit exactly on [rect]'s left
  /// and right edges instead — correct for a line chart's endpoints, but
  /// for a bar chart it means the first/last bar's own half-width always
  /// extends past the plot edge and gets clamped there, rendering as a
  /// visibly thinner, lopsided bar whose score bubble (anchored to the
  /// *unclamped* point) then drifts away from the bar's actual edge.
  static List<Offset?> _computePoints(
    Rect rect,
    List<double?> values,
    double maxY, {
    bool slotted = false,
  }) {
    final count = values.length;
    final stepX = slotted
        ? (count > 0 ? rect.width / count : 0.0)
        : (count > 1 ? rect.width / (count - 1) : 0.0);
    return [
      for (var i = 0; i < count; i++)
        if (values[i] == null)
          null
        else
          Offset(
            rect.left + stepX * (slotted ? i + 0.5 : i.toDouble()),
            rect.bottom - (values[i]! / maxY).clamp(0.0, 1.0) * rect.height,
          ),
    ];
  }
}

/// The small pill shown at each of "my"/the competitor's chart points,
/// carrying a 1-2 letter initials [label].
class _ScoreBubble extends StatelessWidget {
  const _ScoreBubble({
    required this.label,
    required this.pillColor,
    this.solid = false,
  });

  final String label;
  final Color pillColor;

  /// True for the bar/column layout: the circle sits directly on the bar
  /// it labels, so it's filled in that bar's exact color instead of a
  /// softened one.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18.r,
      height: 18.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.surfaceColor(
          solid ? pillColor : pillColor.withValues(alpha: .55),
        ),
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.sp,
          fontWeight: FontWeight.w700,
          color: context.inkColor(Color(0xFF3F4A32)),
        ),
      ),
    );
  }
}

/// Shown when a category column is tapped: the exact myScore/competitorScore
/// values behind that point on the chart.
class _ScoreTooltip extends StatelessWidget {
  const _ScoreTooltip({
    required this.title,
    required this.myLabel,
    required this.myScore,
    required this.competitorLabel,
    required this.competitorScore,
  });

  final String title;
  final String myLabel;
  final double myScore;
  final String competitorLabel;
  final double? competitorScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      constraints: BoxConstraints(minWidth: 112.w),
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // The tooltip sits in a Positioned with no width, so its rows (which
      // use Expanded) need a finite width: IntrinsicWidth provides one.
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: context.inkColor(Colors.black87),
              ),
            ),
            SizedBox(height: 4.h),
            _TooltipRow(
              color: _LineChartPainter.lineColor,
              label: myLabel,
              value: context.localizedDigits(_formatPoints(myScore)),
            ),
            SizedBox(height: 2.h),
            _TooltipRow(
              color: _LineChartPainter.competitorLineColor,
              label: competitorLabel,
              value: competitorScore == null
                  ? '—'
                  : context.localizedDigits(_formatPoints(competitorScore!)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TooltipRow extends StatelessWidget {
  const _TooltipRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7.r,
          height: 7.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 5.w),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.sp,
              color: context.inkColor(Colors.black87),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: context.inkColor(Colors.black),
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.plotRect,
    required this.categories,
    required this.points,
    required this.competitorPoints,
    required this.maxY,
    required this.language,
    this.selectedIndex,
  });

  final Rect plotRect;
  final List<String> categories;
  final List<Offset> points;

  /// Same order as [points]; a `null` entry breaks the dashed line for
  /// that segment instead of interpolating across a pillar the server has
  /// no competitor score for.
  final List<Offset?> competitorPoints;
  final double maxY;
  final AppLanguage language;

  /// The category whose tooltip is open: its column gets a guide line and
  /// its points are drawn enlarged with a halo. Null when none is open.
  final int? selectedIndex;

  static const lineColor = Color(0xFF5D8067);
  // Matches _CompetitorBubble.dotColor / the legend's competitor dot, so
  // "my" vs "competitor" reads as the same color pairing everywhere on
  // the chart.
  static const competitorLineColor = Color(0xFFB9C776);
  static const _areaFillColor = Color(0xFF7C93D6);
  static const _gridColor = Color(0xFFE7E9DD);
  static const _labelColor = Color(0xFF8C9484);
  static const _ySteps = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _gridColor
      ..strokeWidth = 1;

    for (var i = 0; i <= _ySteps; i++) {
      final y = plotRect.bottom - plotRect.height * i / _ySteps;
      canvas.drawLine(
        Offset(plotRect.left, y),
        Offset(plotRect.right, y),
        gridPaint,
      );
      _paintLabel(
        canvas,
        localizeDigits((maxY * i / _ySteps).round().toString(), language),
        Offset(plotRect.left - 6.w, y),
        alignRight: true,
      );
    }

    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, plotRect.bottom)
        ..lineTo(points.first.dx, plotRect.bottom)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _areaFillColor.withValues(alpha: .45),
              _areaFillColor.withValues(alpha: .06),
            ],
          ).createShader(plotRect),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.r
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final selected = selectedIndex;
    if (selected != null && selected >= 0 && selected < points.length) {
      final x = points[selected].dx;
      final guide = Paint()
        ..color = lineColor.withValues(alpha: .45)
        ..strokeWidth = 1.2;
      for (var y = plotRect.top; y < plotRect.bottom; y += 6) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, (y + 3).clamp(plotRect.top, plotRect.bottom)),
          guide,
        );
      }
    }

    for (final point in points) {
      canvas.drawCircle(point, 5.r, Paint()..color = Colors.white);
      canvas.drawCircle(
        point,
        5.r,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.r,
      );
      canvas.drawCircle(point, 2.2.r, Paint()..color = lineColor);
    }

    // Competitor line: dashed, in the legend's competitor color, so "my"
    // (solid green) and "competitor" (dashed olive) are unmistakable at a
    // glance. Drawn as separate contiguous segments so a pillar the server
    // has no competitor score for breaks the line instead of interpolating
    // across it.
    final competitorPaint = Paint()
      ..color = competitorLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.r
      ..strokeCap = StrokeCap.round;
    var segment = <Offset>[];
    void flushSegment() {
      if (segment.length > 1) {
        _drawDashedPolyline(canvas, segment, competitorPaint);
      }
      segment = [];
    }

    for (final point in competitorPoints) {
      if (point == null) {
        flushSegment();
      } else {
        segment.add(point);
      }
    }
    flushSegment();

    for (final point in competitorPoints) {
      if (point == null) continue;
      canvas.drawCircle(point, 3.r, Paint()..color = competitorLineColor);
    }

    // Highlight the selected column's points on top of everything.
    if (selected != null && selected >= 0 && selected < points.length) {
      void highlight(Offset point, Color color) {
        canvas.drawCircle(
          point,
          11.r,
          Paint()..color = color.withValues(alpha: .22),
        );
        canvas.drawCircle(point, 6.5.r, Paint()..color = Colors.white);
        canvas.drawCircle(point, 4.5.r, Paint()..color = color);
      }

      if (selected < competitorPoints.length &&
          competitorPoints[selected] != null) {
        highlight(competitorPoints[selected]!, competitorLineColor);
      }
      highlight(points[selected], lineColor);
    }

    for (var i = 0; i < categories.length; i++) {
      final x = i < points.length ? points[i].dx : plotRect.left;
      canvas.save();
      canvas.translate(x, plotRect.bottom + 10.h);
      canvas.rotate(-0.6);
      _paintLabel(canvas, categories[i], Offset.zero, alignRight: true);
      canvas.restore();
    }
  }

  static void _paintLabel(
    Canvas canvas,
    String text,
    Offset anchor, {
    bool alignRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 9.sp, color: _labelColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = alignRight
        ? Offset(anchor.dx - painter.width, anchor.dy - painter.height / 2)
        : anchor;
    painter.paint(canvas, offset);
  }

  /// Draws [points] as a dashed polyline (no dashing support in
  /// `dart:ui`/Canvas directly, so short solid segments are stepped along
  /// each leg by hand).
  static void _drawDashedPolyline(
    Canvas canvas,
    List<Offset> points,
    Paint paint,
  ) {
    const dashLength = 5.0;
    const gapLength = 4.0;
    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final legLength = (end - start).distance;
      if (legLength == 0) continue;
      final direction = (end - start) / legLength;
      var travelled = 0.0;
      while (travelled < legLength) {
        final dashEnd = (travelled + dashLength).clamp(0.0, legLength);
        canvas.drawLine(
          start + direction * travelled,
          start + direction * dashEnd,
          paint,
        );
        travelled += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.competitorPoints != competitorPoints ||
      oldDelegate.plotRect != plotRect ||
      oldDelegate.language != language ||
      oldDelegate.selectedIndex != selectedIndex;
}

/// Weekly tab's chart style (img reference: Hadith dashboard's weekly bar
/// chart): the same per-pillar `points`/`competitorPoints` [_LineChartPainter]
/// uses, drawn as overlapping columns — taller bar behind, shorter in front —
/// instead of a connected line. Grid, y-axis labels and x-axis category
/// labels are identical to [_LineChartPainter]'s.
class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({
    required this.plotRect,
    required this.categories,
    required this.points,
    required this.competitorPoints,
    required this.tickValues,
    required this.language,
    this.selectedIndex,
    this.verticalLabels = false,
  });

  final Rect plotRect;
  final List<String> categories;
  final List<Offset> points;
  final List<Offset?> competitorPoints;

  /// This window's own data-driven y-axis labels, evenly spaced from `0`
  /// to the axis ceiling (e.g. `[0, 50, 100, 150, 200, 250, 300]`) — see
  /// `_niceAxisTicks`. [points]/[competitorPoints] are already scaled
  /// against the same ceiling (`tickValues.last`), so this list only
  /// needs drawing, not any further ratio math.
  final List<double> tickValues;
  final AppLanguage language;
  final int? selectedIndex;

  /// Monthly's category labels read bottom-to-top instead of leaning
  /// diagonally (reference image).
  final bool verticalLabels;

  /// Every column's bar half-width — all columns (Fardh Prayer, Nafl
  /// Salat, Quran, etc.) are drawn at this same width; only their height
  /// differs, based on actual progress. Derived from the slotted spacing
  /// `_computePoints`/[_AmolLineChartState] use for bar charts (each
  /// category gets an equal `plotWidth / count` slot), so the bar — and
  /// the score bubble [_AmolLineChartState] positions at its top-left
  /// corner — always matches the slot it's actually centered in.
  static double barHalfWidth(int count, double plotWidth) {
    if (count <= 0) return 0.0;
    final stepX = plotWidth / count;
    return (stepX * 0.28).clamp(4.0, 16.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _LineChartPainter._gridColor
      ..strokeWidth = 1;

    // tickValues are evenly spaced by construction (0, step, 2*step, ...),
    // so each one's screen y is just its position in the list over the
    // list's own span — no separate ratio against a ceiling value needed.
    final lastTickIndex = tickValues.length - 1;
    for (var i = 0; i <= lastTickIndex; i++) {
      final y = lastTickIndex == 0
          ? plotRect.bottom
          : plotRect.bottom - plotRect.height * i / lastTickIndex;
      canvas.drawLine(
        Offset(plotRect.left, y),
        Offset(plotRect.right, y),
        gridPaint,
      );
      _LineChartPainter._paintLabel(
        canvas,
        localizeDigits(tickValues[i].round().toString(), language),
        Offset(plotRect.left - 6.w, y),
        alignRight: true,
      );
    }

    final halfWidth = barHalfWidth(points.length, plotRect.width);
    for (var i = 0; i < points.length; i++) {
      final competitor = i < competitorPoints.length
          ? competitorPoints[i]
          : null;
      final bars = <(Offset, Color)>[
        (points[i], _LineChartPainter.lineColor),
        if (competitor != null)
          (competitor, _LineChartPainter.competitorLineColor),
      ]..sort((a, b) => a.$1.dy.compareTo(b.$1.dy));
      for (final (point, color) in bars) {
        final left = (point.dx - halfWidth).clamp(
          plotRect.left,
          plotRect.right,
        );
        final right = (point.dx + halfWidth).clamp(
          plotRect.left,
          plotRect.right,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTRB(left, point.dy, right, plotRect.bottom),
            topLeft: Radius.circular(4.r),
            topRight: Radius.circular(4.r),
          ),
          Paint()..color = color,
        );
      }
    }

    // Highlight the selected column, same treatment as the line chart's.
    final selected = selectedIndex;
    if (selected != null && selected >= 0 && selected < points.length) {
      final x = points[selected].dx;
      final guide = Paint()
        ..color = _LineChartPainter.lineColor.withValues(alpha: .45)
        ..strokeWidth = 1.2;
      for (var y = plotRect.top; y < plotRect.bottom; y += 6) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, (y + 3).clamp(plotRect.top, plotRect.bottom)),
          guide,
        );
      }

      void highlight(Offset point, Color color) {
        canvas.drawCircle(
          point,
          11.r,
          Paint()..color = color.withValues(alpha: .22),
        );
        canvas.drawCircle(point, 6.5.r, Paint()..color = Colors.white);
        canvas.drawCircle(point, 4.5.r, Paint()..color = color);
      }

      if (selected < competitorPoints.length &&
          competitorPoints[selected] != null) {
        highlight(
          competitorPoints[selected]!,
          _LineChartPainter.competitorLineColor,
        );
      }
      highlight(points[selected], _LineChartPainter.lineColor);
    }

    for (var i = 0; i < categories.length; i++) {
      final x = i < points.length ? points[i].dx : plotRect.left;
      canvas.save();
      canvas.translate(x, plotRect.bottom + 10.h);
      canvas.rotate(verticalLabels ? -math.pi / 2 : -0.6);
      _LineChartPainter._paintLabel(
        canvas,
        categories[i],
        Offset.zero,
        alignRight: true,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.competitorPoints != competitorPoints ||
      oldDelegate.tickValues != tickValues ||
      oldDelegate.verticalLabels != verticalLabels ||
      oldDelegate.plotRect != plotRect ||
      oldDelegate.language != language ||
      oldDelegate.selectedIndex != selectedIndex;
}

class _MyPointsBar extends StatelessWidget {
  const _MyPointsBar({required this.myPoints, required this.totalPoints});

  final int myPoints;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: ShapeDecoration(
        color: context.surfaceColor(Color(0xFFDCE7AC)),
        shape: StadiumBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                context.localizedDigits(
                  '${AppText.of(context).myPoints} : $myPoints',
                ),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: context.inkColor(Colors.black),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                decoration: const BoxDecoration(
                  color: Color(0xFF5D8067),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 5.w),
              Text(
                context.localizedDigits('$totalPoints'),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.inkColor(Colors.black87),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
