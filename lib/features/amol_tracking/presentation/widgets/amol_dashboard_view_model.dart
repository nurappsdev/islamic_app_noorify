import 'package:flutter/widgets.dart';

import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_analytics_point.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/bloc/amol_dashboard_bloc.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_localized_format.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_shared_widgets.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_context.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

import 'amol_dashboard_period.dart';
import 'amol_dashboard_utils.dart';

/// Every piece of display-ready data the dashboard screen's widget tree
/// needs, derived once from [AmolDashboardState] (and the current
/// language/profile) instead of recomputed inline across the screen's
/// `build()`. Pure presentation mapping — no business logic lives here
/// beyond picking which already-loaded field to show and formatting it.
class AmolDashboardViewModel {
  AmolDashboardViewModel._({
    required this.period,
    required this.myLabel,
    required this.competitorLabel,
    required this.pointLabel,
    required this.progressLabel,
    required this.progress,
    required this.myPoints,
    required this.totalPoints,
    required this.maxY,
    required this.rangeLabel,
    required this.showMonthlyPillars,
    required this.hasMonthlyPillars,
    required this.chartCategories,
    required this.chartValues,
    required this.chartCompetitorValues,
    required this.isColumnLayout,
    required this.isChartScrollable,
    required this.hasPrevious,
    required this.hasNext,
  });

  // Shown before the first `GET /amol/analytics/graph` response lands.
  static const _fallbackMyPosition = [
    6.0,
    10.0,
    2.0,
    9.0,
    2.0,
    10.0,
    3.0,
    1.0,
    3.0,
  ];
  static const _fallbackCompetitorValues = [
    6.0,
    9.0,
    null,
    8.0,
    null,
    11.0,
    null,
    null,
    2.0,
  ];
  static const _fallbackPoints = 27;
  static const _fallbackTotalPoints = 40;

  factory AmolDashboardViewModel.fromState(
    BuildContext context,
    AmolDashboardState state,
  ) {
    final appText = AppText.of(context);
    final language = languageOf(context);
    final period = AmolPeriod.values[state.selectedPeriod];
    final categories = [
      appText.categoryFardhPrayer,
      appText.categorySunnahAndWitr,
      appText.categoryQuran,
      appText.categoryNaflSalat,
      appText.categoryHadith,
      appText.categoryQuiz,
      appText.categoryZikr,
      appText.duaIntroTitle,
      appText.categoryNaflAndMore,
    ];
    final graph = state.graph;
    final values = graph == null
        ? _fallbackMyPosition
        : [for (final key in kAmolPillarOrder) graph.valueFor(key).toDouble()];
    final competitorValues = graph == null
        ? _fallbackCompetitorValues
        : [
            for (final key in kAmolPillarOrder)
              graph.competitorValueFor(key)?.toDouble(),
          ];
    final competitorLabel = graph == null
        ? appText.competitorInitials
        : amolInitials(
            graph.competitorName,
            fallback: appText.competitorInitials,
          );
    // The signed-in device's own name (set on the profile screen), not
    // anything from the server response — mirrors the competitor's pill
    // but labeled with the local user's initials instead.
    final myLabel = amolInitials(
      profileNameNotifier.value ?? appText.competitorName,
      fallback: language == AppLanguage.bangla ? 'আমি' : 'Me',
    );
    // Use the server's summary totals and percentage, then format the
    // visible point label in the selected language.
    final summary = graph?.summary;
    final myPoints = graph == null
        ? _fallbackPoints
        : (summary?.totalEarnedPoints ?? graph.myTotalPoints).round();
    final totalPoints = graph == null
        ? _fallbackTotalPoints
        : (summary?.totalPossiblePoints ?? graph.maxTotalPoints).round();
    final pointLabel = graph == null
        ? formatAmolPoints(30, 40, appText, language)
        : formatAmolPoints(
            summary?.totalEarnedPoints ?? graph.myTotalPoints,
            summary?.totalPossiblePoints ?? graph.maxTotalPoints,
            appText,
            language,
          );
    final percentValue = graph == null
        ? 86.0
        : (summary?.percentage ??
                  graph.serverCompletionPercentage ??
                  graph.completionPercentage)
              .toDouble();
    final progress = (percentValue / 100).clamp(0.0, 1.0);
    final progressLabel = context.localizedDigits('${percentValue.round()} %');
    // A zero/missing yAxisMax used to produce invalid daily point offsets
    // (0 / 0) and leave the graph blank. Keep the server scale when valid;
    // otherwise derive a safe ceiling from the displayed pillars.
    final maximumValue = values.fold<double>(
      0,
      (maximum, value) => value > maximum ? value : maximum,
    );
    final maxY = graph == null
        ? 12.0
        : graph.yAxisMax > 0
        ? graph.yAxisMax.toDouble()
        : maximumValue > 0
        ? maximumValue
        : 1.0;
    // Prefer the server's own resolved range (it's the ground truth for
    // exactly which days the response covers) over a locally-guessed
    // label; only fall back to local formatting before the first response
    // lands. Format the server's resolved ISO dates with local month
    // names and digits.
    final resolvedRange = graph?.range;
    final localizedRange = resolvedRange == null
        ? ''
        : formatAmolRange(
            resolvedRange.startDate,
            resolvedRange.endDate,
            appText,
            language,
          );
    final rangeLabel = localizedRange.isNotEmpty
        ? localizedRange
        : context.localizedDigits(
            period == AmolPeriod.daily
                ? formatAmolDate(state.date, appText)
                : '${formatAmolDate(startOfAmolWindow(period, state), appText)} - ${formatAmolDate(state.date, appText)}',
          );
    // Monthly shows the same real per-pillar categories as daily/weekly,
    // but reads them straight off the loaded graph's own `pillars` instead
    // of the fixed `kAmolPillarOrder`/`categories` above — so any category
    // the server actually returns (e.g. one this hardcoded list doesn't
    // cover) still shows up, instead of being silently dropped.
    final monthlyPillars = graph?.pillars ?? const <AmolAnalyticsPoint>[];
    final isBangla = language == AppLanguage.bangla;
    final showMonthlyPillars = period == AmolPeriod.monthly && graph != null;
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
    // `niceAmolAxisTicks`) instead of using the server's `maxY`. Daily
    // keeps the server's `maxY` as-is.
    final isColumnLayout = period == AmolPeriod.weekly || showMonthlyPillars;
    // There are now nine daily/weekly pillars, including Zikr and Dua.
    // Keep every point and its label reachable on narrow screens instead of
    // squeezing the additional two categories into the old seven-column
    // width.
    final isChartScrollable = isColumnLayout || chartCategories.length > 7;
    final navigation = graph?.navigation;
    final hasPrevious = navigation == null || navigation.hasPrevious;
    // Whether stepping "next" would go anywhere: computed locally rather
    // than trusted from the server's `navigation.hasNext` — that field
    // wasn't reliably flipping true again after navigating back with
    // "previous" (across daily/weekly/monthly alike, including daily,
    // which never even sends an `offset`), permanently disabling the next
    // arrow. Since `ShiftDate` already clamps forward movement to never
    // pass today, whether "next" has anywhere to go is fully known
    // locally: yes, whenever the viewed date isn't already today.
    final hasNext = !isSameAmolDate(state.date, state.today);

    return AmolDashboardViewModel._(
      period: period,
      myLabel: myLabel,
      competitorLabel: competitorLabel,
      pointLabel: pointLabel,
      progressLabel: progressLabel,
      progress: progress,
      myPoints: myPoints,
      totalPoints: totalPoints,
      maxY: maxY,
      rangeLabel: rangeLabel,
      showMonthlyPillars: showMonthlyPillars,
      hasMonthlyPillars: monthlyPillars.isNotEmpty,
      chartCategories: chartCategories,
      chartValues: chartValues,
      chartCompetitorValues: chartCompetitorValues,
      isColumnLayout: isColumnLayout,
      isChartScrollable: isChartScrollable,
      hasPrevious: hasPrevious,
      hasNext: hasNext,
    );
  }

  final AmolPeriod period;
  final String myLabel;
  final String competitorLabel;
  final String pointLabel;
  final String progressLabel;
  final double progress;
  final int myPoints;
  final int totalPoints;
  final double maxY;
  final String rangeLabel;

  /// True only for the monthly tab, and only once its graph has loaded —
  /// gates both the real-pillars chart data below and the chart's
  /// empty-state branch.
  final bool showMonthlyPillars;

  /// False when [showMonthlyPillars] is true but the server returned no
  /// pillars for the selected month (shows the empty state instead of a
  /// blank chart). Always true outside the monthly tab.
  final bool hasMonthlyPillars;

  final List<String> chartCategories;
  final List<double> chartValues;
  final List<double?> chartCompetitorValues;

  /// True for weekly and monthly — drawn as bar columns instead of a line.
  final bool isColumnLayout;

  /// Lets daily fit newly added pillars without overlapping/cutting labels.
  final bool isChartScrollable;

  final bool hasPrevious;
  final bool hasNext;
}
