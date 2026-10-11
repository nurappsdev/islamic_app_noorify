import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/datasources/amol_analytics_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/repositories/amol_analytics_repository_impl.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/get_amol_analytics_graph.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/bloc/amol_dashboard_bloc.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_average_caption.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_dashboard_period.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_dashboard_utils.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_dashboard_view_model.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_date_navigator.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_legend.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_line_chart.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_month_dropdown.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_my_points_bar.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_period_tabs.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_shared_widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AmolDashboardBloc>().state;
    final bloc = context.read<AmolDashboardBloc>();
    final appText = AppText.of(context);
    final vm = AmolDashboardViewModel.fromState(context, state);
    final period = vm.period;

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
                  AmolPeriodTabs(
                    period: period,
                    onChanged: (value) => bloc.add(SelectPeriod(value.index)),
                  ),
                  SizedBox(height: 16.h),
                  AmolSummaryCard(
                    title: period.summaryCardTitle(appText),
                    pointLabel: vm.pointLabel,
                    progressLabel: vm.progressLabel,
                    progress: vm.progress,
                  ),
                  SizedBox(height: 14.h),
                  AmolDateNavigator(
                    label: vm.rangeLabel,
                    subtitle: '${period.label(appText)} ${appText.amolTrack}',
                    onPrevious: vm.hasPrevious
                        ? () => bloc.add(ShiftDate(period.step, -1))
                        : null,
                    onNext: vm.hasNext
                        ? () => bloc.add(ShiftDate(period.step, 1))
                        : null,
                  ),
                  if (period == AmolPeriod.monthly) ...[
                    SizedBox(height: 10.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AmolMonthDropdown(
                        selectedMonth: DateTime(
                          state.date.year,
                          state.date.month,
                        ),
                        months: lastTwelveAmolMonths(state.today),
                        appText: appText,
                        onChanged: (month) => bloc.add(SelectMonth(month)),
                      ),
                    ),
                  ],
                  SizedBox(height: 18.h),
                  AmolAverageCaption(period: period),
                  SizedBox(height: 12.h),
                  const AmolLegend(),
                  SizedBox(height: 10.h),
                  if (vm.showMonthlyPillars && !vm.hasMonthlyPillars)
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
                    AmolLineChart(
                      categories: vm.chartCategories,
                      values: vm.chartValues,
                      myLabel: vm.myLabel,
                      competitorValues: vm.chartCompetitorValues,
                      competitorLabel: vm.competitorLabel,
                      maxY: vm.maxY,
                      // Weekly mirrors the Hadith dashboard's weekly tab:
                      // the same per-pillar data, drawn as columns instead
                      // of a line. Monthly uses every real category (not
                      // just the fixed list above) with vertical, scrollable
                      // labels; tapping a column shows the same my/competitor
                      // points tooltip weekly uses. Daily keeps the existing
                      // line chart.
                      columnLayout: vm.isColumnLayout,
                      verticalLabels: vm.showMonthlyPillars,
                      // Weekly's fixed 7-category list (including Nafl
                      // Salat and Nafl And More, the last two) can run off
                      // the screen edge with diagonal labels on a narrow
                      // device — scrollable horizontally, same as monthly,
                      // so every category stays reachable by swiping.
                      scrollable: vm.isColumnLayout,
                    ),
                  SizedBox(height: 18.h),
                  AmolMyPointsBar(
                    myPoints: vm.myPoints,
                    totalPoints: vm.totalPoints,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
