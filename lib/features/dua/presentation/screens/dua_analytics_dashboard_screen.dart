import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_home_cubit.dart'
    show DuaLoadStatus;
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_reading_dashboard_cubit.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bottom_nav.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_dashboard_charts.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_shimmer.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_status_view.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';

/// Dua reading dashboard (design `devImg/img_41.png`), fed by
/// `GET /duas/reading/dashboard?timeframe=daily|weekly|monthly`.
///
/// Daily draws the position donut, Weekly the seven-day columns and Monthly
/// the per-week rows; the two metric cards and the recitation history below
/// them come from the same answer. Switching the dropdown re-reads the
/// endpoint, and a window already loaded comes straight back from
/// [DuaReadingDashboardCubit]'s cache.
class DuaAnalyticsDashboardScreen extends StatelessWidget {
  const DuaAnalyticsDashboardScreen({super.key, this.repository});

  /// Test seam; the app's own [duaRepository] is used when it is left out.
  final DuaRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        DuaReadingDashboardCubit(repository ?? duaRepository)..load(),
    child: const _DuaAnalyticsDashboardView(),
  );
}

class _DuaAnalyticsDashboardView extends StatelessWidget {
  const _DuaAnalyticsDashboardView();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child:
                BlocBuilder<DuaReadingDashboardCubit, DuaReadingDashboardState>(
                  builder: (context, state) {
                    final cubit = context.read<DuaReadingDashboardCubit>();
                    final dashboard = state.dashboard;
                    return Column(
                      children: [
                        _DashboardHeader(
                          timeframe: state.timeframe,
                          onChanged: cubit.select,
                        ),
                        if (state.refreshing)
                          SizedBox(
                            height: 2.h,
                            child: const LinearProgressIndicator(minHeight: 2),
                          ),
                        Expanded(
                          child: switch (state) {
                            _ when dashboard != null => _DashboardBody(
                              state: state,
                              dashboard: dashboard,
                              onRefresh: () => cubit.load(silent: true),
                            ),
                            _ when state.status == DuaLoadStatus.failure =>
                              DuaErrorRetry(
                                message: AppText.of(
                                  context,
                                ).duaDashboardLoadFailed,
                                onRetry: cubit.load,
                              ),
                            _ => const DuaReadingDashboardShimmer(),
                          },
                        ),
                        // Room for the floating bar in the Stack above.
                        SizedBox(height: 92.h + bottomInset),
                      ],
                    );
                  },
                ),
          ),
          const SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DuaBottomNav(selectedIndex: 4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.state,
    required this.dashboard,
    required this.onRefresh,
  });

  final DuaReadingDashboardState state;
  final DuaReadingDashboard dashboard;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        // Always scrollable, so a short answer can still be pulled down.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
        children: [
          _PositionSummary(dashboard: dashboard),
          SizedBox(height: 14.h),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey(state.timeframe),
              child: _TimeframeChart(
                timeframe: state.timeframe,
                dashboard: dashboard,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _Metrics(dashboard: dashboard),
          SizedBox(height: 20.h),
          _HistoryHeader(
            onSeeAll: () => Navigator.of(
              context,
            ).pushNamed(RouteNames.duaRecitationHistory),
          ),
          SizedBox(height: 4.h),
          _RecitationHistory(items: dashboard.recentRecitations),
        ],
      ),
    );
  }
}

/// The user's own name as the tooltips address them. Before a profile has
/// loaded there is no name to show, so the legend's wording stands in —
/// never the competitor's name, which labels the other row.
String _readerName(BuildContext context) {
  final name = profileNameNotifier.value?.trim();
  return name == null || name.isEmpty ? AppText.of(context).myPosition : name;
}

String _minutes(BuildContext context, int minutes) =>
    context.localizedDigits('$minutes ${AppText.of(context).minLabel}');

class _TimeframeChart extends StatelessWidget {
  const _TimeframeChart({required this.timeframe, required this.dashboard});

  final DuaDashboardTimeframe timeframe;
  final DuaReadingDashboard dashboard;

  /// The minutes the server itself timed for [side], or `null` when it sent
  /// no time — `readingMinutes` would read that as a real zero.
  static int? _timed(DuaComparisonSide? side) =>
      side != null && side.hasTime ? side.readingMinutes : null;

  /// The rival's minutes for a bar: the server's own figure when it sent
  /// one, else the window-wide split applied to [mine]. `null` when neither
  /// is knowable, so nothing invents a zero.
  int? _rivalMinutes(DuaComparison comparison, int? mine) {
    final timed = _timed(comparison.rival);
    if (timed != null) return timed;
    if (mine == null || dashboard.myPositionPercentage <= 0) return null;
    return duaCompetitorValue(
      mine,
      myPercentage: dashboard.myPositionPercentage,
      competitorPercentage: dashboard.competitorPercentage,
    );
  }

  /// A side's time: what the server formatted, else [minutes] written out,
  /// else a dash. A real zero still reads `0 min`; only an unknown is
  /// dashed.
  String _time(BuildContext context, DuaComparisonSide? side, int? minutes) {
    if (side != null && side.hasTime) {
      return context.localizedDigits(side.readingTimeFormatted);
    }
    return minutes == null ? '—' : _minutes(context, minutes);
  }

  /// The two rows a tooltip ends with: the user and the rival, each named
  /// and timed as the server has them, beside the colour its layer is drawn
  /// in. Each side's `pointsText` follows on its own quieter line.
  List<DuaTooltipLine> _shares(
    BuildContext context,
    DuaComparison comparison, {
    required int? myMinutes,
    required int? rivalMinutes,
    String myPointsFallback = '',
  }) {
    final appText = AppText.of(context);
    final me = comparison.me;
    final rival = comparison.rival;
    final myPoints = me?.pointsText.isNotEmpty == true
        ? me!.pointsText
        : myPointsFallback;
    return [
      DuaTooltipLine.metric(
        color: DuaChartColors.mine,
        text: me?.name.isNotEmpty == true ? me!.name : _readerName(context),
        value: _time(context, me, myMinutes),
      ),
      if (myPoints.isNotEmpty)
        DuaTooltipLine.note(context.localizedDigits(myPoints)),
      DuaTooltipLine.metric(
        color: DuaChartColors.competitor,
        text: rival?.name.isNotEmpty == true
            ? rival!.name
            : appText.competitorName,
        value: _time(context, rival, rivalMinutes),
      ),
      if (rival?.pointsText.isNotEmpty == true)
        DuaTooltipLine.note(context.localizedDigits(rival!.pointsText)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);

    switch (timeframe) {
      case DuaDashboardTimeframe.daily:
        // The day's own minutes when the server sends `today`, else the
        // window total it did send, else nothing to go on.
        final today = dashboard.today;
        final myMinutes =
            today?.readMinutes ??
            (dashboard.totalReadingTimeFormatted.isEmpty
                ? null
                : duaParseReadingMinutes(dashboard.totalReadingTimeFormatted));
        final fallbackTime = today == null
            ? dashboard.totalReadingTimeFormatted
            : _minutes(context, today.readMinutes);
        return DuaDonutChart(
          myPercentage: dashboard.myPositionPercentage,
          competitorPercentage: dashboard.competitorPercentage,
          tooltip: DuaChartTooltip(
            // With the comparison the card names both sides on its own
            // rows, so it needs no heading repeating one of them.
            title: dashboard.comparison.isEmpty ? _readerName(context) : '',
            lines: dashboard.comparison.isEmpty
                ? [
                    DuaTooltipLine.text(
                      appText.duaDashboardTimeLabel.fill({
                        'value': fallbackTime,
                      }),
                    ),
                    DuaTooltipLine.text(
                      appText.duaDashboardPointLabel.fill({
                        'value': context.localizedDigits(
                          dashboard.dailyTargetText,
                        ),
                      }),
                    ),
                  ]
                : _shares(
                    context,
                    dashboard.comparison,
                    myMinutes: myMinutes,
                    rivalMinutes: _rivalMinutes(
                      dashboard.comparison,
                      myMinutes,
                    ),
                    // The day's target fraction stands in when the server
                    // sends no points of its own.
                    myPointsFallback: dashboard.dailyTargetText.isEmpty
                        ? ''
                        : appText.duaDashboardPointLabel.fill({
                            'value': dashboard.dailyTargetText,
                          }),
                  ),
          ),
        );

      case DuaDashboardTimeframe.weekly:
        final days = dashboard.activity;
        return DuaWeeklyBarChart(
          bars: [
            for (final day in days)
              DuaChartBar(
                label: day.label,
                mine: day.minutes,
                competitor: _rivalMinutes(day.comparison, day.minutes) ?? 0,
              ),
          ],
          tooltipBuilder: (index, bar) {
            final day = days[index];
            return DuaChartTooltip(
              title: bar.title,
              lines: _shares(
                context,
                day.comparison,
                myMinutes: day.minutes,
                rivalMinutes: _rivalMinutes(day.comparison, day.minutes),
              ),
            );
          },
        );

      case DuaDashboardTimeframe.monthly:
        final rows = _monthlyRows(appText);
        return DuaMonthlyBarChart(
          bars: [
            for (final row in rows)
              DuaChartBar(
                // The axis carries the day the span ends on; which days it
                // covers is spelled out in the tooltip.
                label: duaPeriodAxisLabel(row.label),
                title: row.label,
                mine: row.minutes,
                competitor: _rivalMinutes(row.comparison, row.minutes) ?? 0,
              ),
          ],
          tooltipBuilder: (index, bar) {
            final row = rows[index];
            return DuaChartTooltip(
              title: context.localizedDigits(bar.title),
              lines: _shares(
                context,
                row.comparison,
                myMinutes: row.minutes,
                rivalMinutes: _rivalMinutes(row.comparison, row.minutes),
              ),
            );
          },
        );
    }
  }

  /// The monthly rows: the server's own `monthlyActivity.periods[]` when it
  /// sends them, else the month's days bucketed into spans here.
  List<DuaDashboardPeriod> _monthlyRows(AppText appText) {
    if (dashboard.periods.isNotEmpty) return dashboard.periods;
    return [
      for (final bucket in duaMonthlyBuckets(dashboard.activity))
        DuaDashboardPeriod(
          label: bucket.isSingleDay
              ? bucket.dayLabel
              : appText.duaDashboardWeekRange.fill({
                  'from': bucket.fromDay + 1,
                  'to': bucket.toDay,
                }),
          comparison: const DuaComparison(),
          minutes: bucket.minutes,
        ),
    ];
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.timeframe, required this.onChanged});

  final DuaDashboardTimeframe timeframe;
  final ValueChanged<DuaDashboardTimeframe> onChanged;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 6.h),
      child: SizedBox(
        height: 44.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 34.r,
                  height: 34.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.surfaceColor(const Color(0xFFF1F6E0)),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15.sp,
                    color: context.inkColor(const Color(0xFF83915E)),
                  ),
                ),
              ),
            ),
            Text(
              appText.dashboard,
              style: TextStyle(
                color: context.inkColor(const Color(0xFF83915E)),
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<DuaDashboardTimeframe>(
                onSelected: onChanged,
                initialValue: timeframe,
                color: context.surfaceColor(Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                itemBuilder: (_) => [
                  for (final value in DuaDashboardTimeframe.values)
                    PopupMenuItem(
                      value: value,
                      child: Text(value.label(appText)),
                    ),
                ],
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 9.h,
                  ),
                  decoration: BoxDecoration(
                    color: context.surfaceColor(const Color(0xFFE0EABD)),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeframe.label(appText),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.inkColor(const Color(0xFF3F4A28)),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18.sp,
                        color: context.inkColor(const Color(0xFF3F4A28)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on DuaDashboardTimeframe {
  String label(AppText appText) => switch (this) {
    DuaDashboardTimeframe.daily => appText.daily,
    DuaDashboardTimeframe.weekly => appText.weekly,
    DuaDashboardTimeframe.monthly => appText.monthly,
  };
}

class _PositionSummary extends StatelessWidget {
  const _PositionSummary({required this.dashboard});

  final DuaReadingDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(const Color(0xFFF5F8E8)),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          const _LegendDot(color: DuaChartColors.mine),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              appText.myPosition,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.inkColor(const Color(0xFF97A64D)),
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          _PercentagePill(value: dashboard.myPositionPercentage),
          const Spacer(),
          const _LegendDot(color: Color(0xFFF0EEC1)),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              appText.duaDashboardCompetitor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.inkColor(const Color(0xFF687484)),
                fontSize: 12.sp,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          _PercentagePill(value: dashboard.competitorPercentage, muted: true),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 9.r,
    height: 9.r,
    decoration: BoxDecoration(
      color: context.surfaceColor(color),
      shape: BoxShape.circle,
    ),
  );
}

class _PercentagePill extends StatelessWidget {
  const _PercentagePill({required this.value, this.muted = false});
  final double value;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
    decoration: BoxDecoration(
      color: context.surfaceColor(
        muted ? const Color(0xFFC2CF92) : const Color(0xFFA6B65B),
      ),
      borderRadius: BorderRadius.circular(4.r),
    ),
    child: Text(
      context.localizedDigits('${value.round()}%'),
      style: TextStyle(
        color: Colors.white,
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.dashboard});
  final DuaReadingDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: appText.duaTotalRecitedTitle,
            value: context.localizedDigits('${dashboard.totalDuasRecited}'),
            subtitle: appText.duaDailyTargetLabel.fill({
              'value': context.localizedDigits(
                dashboard.dailyTargetText.isEmpty
                    ? '—'
                    : dashboard.dailyTargetText,
              ),
            }),
            colors: const [Color(0xFF782CEB), Color(0xFF5245D7)],
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _MetricCard(
            title: appText.duaRecitationTimeTitle,
            value: context.localizedDigits(
              dashboard.totalReadingTimeFormatted.isEmpty
                  ? '—'
                  : dashboard.totalReadingTimeFormatted,
            ),
            subtitle: appText.duaTotalRecitationTime,
            colors: const [Color(0xFF08BCEB), Color(0xFF2365DD)],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.colors,
  });

  final String title;
  final String value;
  final String subtitle;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Container(
    height: 122.h,
    padding: EdgeInsets.all(13.r),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      borderRadius: BorderRadius.circular(21.r),
      boxShadow: [
        BoxShadow(
          color: colors.last.withValues(alpha: .22),
          blurRadius: 12.r,
          offset: Offset(0, 5.h),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white, fontSize: 10.sp),
        ),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white, fontSize: 8.sp),
        ),
      ],
    ),
  );
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.onSeeAll});
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            appText.duaRecitationHistoryTitle,
            style: TextStyle(
              color: context.inkColor(const Color(0xFF181818)),
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        InkWell(
          onTap: onSeeAll,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.all(4.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appText.seeAll,
                  style: TextStyle(
                    color: context.textInkColor(const Color(0xFF98A46C)),
                    fontSize: 11.sp,
                  ),
                ),
                Container(
                  width: 49.w,
                  height: 1.h,
                  color: context.lineColor(const Color(0xFF98A46C)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecitationHistory extends StatelessWidget {
  const _RecitationHistory({required this.items});

  final List<DuaReadingHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Text(
          AppText.of(context).duaNoRecitationHistory,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.sp,
            color: context.textInkColor(const Color(0xFF778060)),
          ),
        ),
      );
    }
    return Column(
      children: [for (final item in items.take(5)) _HistoryRow(item: item)],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});

  final DuaReadingHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 9.h),
      child: Row(
        children: [
          Container(
            width: 31.r,
            height: 31.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.lineColor(const Color(0xFFC7D590)),
              ),
            ),
            child: Icon(
              Icons.menu_book_outlined,
              color: context.inkColor(const Color(0xFFA6B65B)),
              size: 17.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.localized(item.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _subtitle(context, item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5.sp,
                    color: context.textInkColor(const Color(0xFF778060)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 88.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  context.localizedDigits(_time(context, item)),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 8.5.sp,
                    color: context.textInkColor(const Color(0xFF97A64D)),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  context.localizedDigits(_read(appText, item)),
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: context.textInkColor(const Color(0xFF778060)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The category the dua belongs to, plus how many of its duas were read —
/// the arabic opening stands in when the server sends no category.
String _subtitle(BuildContext context, DuaReadingHistoryItem item) {
  final appText = AppText.of(context);
  final category = context.localized(item.category);
  final lead = category.isNotEmpty ? category : item.arabic;
  if (item.readCount <= 0) return lead;
  final count = context.localizedDigits(
    appText.duaSavedCount.fill({'n': item.readCount}),
  );
  return lead.isEmpty ? count : '$lead • $count';
}

/// `timeAgoText` as the server formats it, or the stored timestamp in the
/// device's own format when it is missing.
String _time(BuildContext context, DuaReadingHistoryItem item) {
  if (item.timeAgoText.isNotEmpty) return item.timeAgoText;
  final time = item.lastReadAt?.toLocal();
  if (time == null) return '—';
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatShortDate(time)} '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(time))}';
}

/// Minutes read when the server sends seconds; otherwise how many times the
/// dua was recited.
String _read(AppText appText, DuaReadingHistoryItem item) {
  if (item.readSeconds > 0) {
    return appText.duaMinutesRead.fill({'n': (item.readSeconds / 60).ceil()});
  }
  if (item.readCount > 0) {
    return appText.duaTimesRead.fill({'n': item.readCount});
  }
  return '—';
}
