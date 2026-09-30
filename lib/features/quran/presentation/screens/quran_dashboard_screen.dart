import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import '../../data/repositories/quran_reading_repository_impl.dart';
import '../../data/services/quran_local_store.dart';
import '../../domain/quran_reading_history.dart';
import '../../domain/quran_reading_progress.dart';
import '../../domain/repositories/quran_reading_repository.dart';
import '../bloc/quran_reading_dashboard/quran_reading_dashboard_cubit.dart';
import '../quran_route_args.dart';
import '../quran_text.dart';
import '../widgets/dashboard/quran_dashboard_charts.dart';
import '../widgets/dashboard/quran_dashboard_header.dart';
import '../widgets/dashboard/quran_dashboard_legend.dart';
import '../widgets/dashboard/quran_period_dropdown.dart';
import '../widgets/dashboard/quran_reading_summary.dart';
import '../widgets/dashboard/quran_stat_cards.dart';
import '../widgets/quran_design.dart' show QuranRetry;

export '../widgets/dashboard/quran_period_dropdown.dart'
    show QuranDashboardPeriod, QuranHistoryPeriod;

/// Quran module reading dashboard screen.
///
/// - Header with circular back button and Dashboard title.
/// - Filter row with "My Position", "My Nearest Or Competitor" toggle, and
///   the period dropdown filter (Daily / Weekly / Monthly + 12-month picker).
/// - Chart of the reading history (`GET /quran/reading/history`) against the
///   compared user's (`GET /quran/reading/history/compare`) for the period.
/// - Total reading time and most read Surah cards.
/// - Today's goal, the week, completion, plans and "Continue reading"
///   (`GET /quran/reading/dashboard`).
class QuranDashboardScreen extends StatefulWidget {
  const QuranDashboardScreen({
    super.key,
    this.onBack,
    this.active = true,
    this.repository,
  });

  final VoidCallback? onBack;

  /// Whether this tab is the one on screen; becoming active refreshes it.
  final bool active;

  /// The reading data; the app-wide repository by default.
  final QuranReadingRepository? repository;

  @override
  State<QuranDashboardScreen> createState() => _QuranDashboardScreenState();
}

class _QuranDashboardScreenState extends State<QuranDashboardScreen> {
  late final QuranReadingDashboardCubit _cubit = QuranReadingDashboardCubit(
    widget.repository ?? QuranReadingRepositoryImpl.shared,
  );
  bool _showCompetitor = true;

  final ScrollController _monthlyScrollController = ScrollController();
  double _monthlyScrollProgress = 0.0;

  // The API has no per-Surah totals, so the most read Surah comes from this
  // device's reading history.
  ({int number, String name}) _mostReadSurah = (number: 55, name: 'Ar-Rahman');

  @override
  void initState() {
    super.initState();
    _monthlyScrollController.addListener(_onMonthlyScroll);
    if (widget.active) _cubit.load();
    _loadStoreData();
  }

  @override
  void didUpdateWidget(QuranDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _cubit.load();
  }

  @override
  void dispose() {
    _monthlyScrollController.removeListener(_onMonthlyScroll);
    _monthlyScrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onMonthlyScroll() {
    if (!_monthlyScrollController.hasClients) return;
    final maxScroll = _monthlyScrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      if (_monthlyScrollProgress != 0) {
        setState(() => _monthlyScrollProgress = 0);
      }
      return;
    }
    final progress = (_monthlyScrollController.offset / maxScroll).clamp(
      0.0,
      1.0,
    );
    if ((progress - _monthlyScrollProgress).abs() > 0.005) {
      setState(() => _monthlyScrollProgress = progress);
    }
  }

  Future<void> _loadStoreData() async {
    try {
      final store = await QuranLocalStore.create();
      final history = await store.history();
      if (history.isNotEmpty && mounted) {
        final surahCounts = <int, int>{};
        final names = <int, String>{};
        for (final entry in history) {
          surahCounts[entry.surahNo] = (surahCounts[entry.surahNo] ?? 0) + 1;
          if (entry.surahName.isNotEmpty) {
            names[entry.surahNo] = entry.surahName;
          }
        }
        if (surahCounts.isNotEmpty) {
          final top = surahCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          setState(() {
            _mostReadSurah = (number: top, name: names[top] ?? '');
          });
        }
      }
    } catch (_) {}
  }

  void _setCompetitor(bool value) {
    setState(() => _showCompetitor = value);
  }

  void _continue(QuranAyahPosition ayah) => Navigator.pushNamed(
    context,
    RouteNames.quranSurahDetail,
    arguments: SurahRouteArgs(
      surahNo: ayah.surahNumber,
      surahName: ayah.surahNameEnglish,
      ayahNo: ayah.ayahNumber,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final t = QuranText.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: context.pageColor(Colors.white),
        body: SafeArea(
          bottom: false,
          child:
              BlocBuilder<
                QuranReadingDashboardCubit,
                QuranReadingDashboardState
              >(
                builder: (context, state) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 8.h),

                      // 1. Top Header: Back circle button and centered title
                      QuranDashboardHeader(
                        title: appText.dashboard.isNotEmpty
                            ? appText.dashboard
                            : 'Dashboard',
                      ),

                      SizedBox(height: 18.h),

                      // 2. Legends & Period Filter Dropdown
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                QuranLegendDot(
                                  color: const Color(0xFF5D7858),
                                  label: appText.myPosition.isNotEmpty
                                      ? appText.myPosition
                                      : 'My Position',
                                ),
                                SizedBox(height: 6.h),
                                QuranLegendToggle(
                                  color: const Color(0xFF8F9F4A),
                                  label:
                                      appText.myNearestOrCompetitor.isNotEmpty
                                      ? appText.myNearestOrCompetitor
                                      : 'My Nearest Or Competitor',
                                  value: _showCompetitor,
                                  onChanged: _setCompetitor,
                                ),
                              ],
                            ),
                          ),
                          QuranPeriodDropdown(
                            period: state.period,
                            month: state.month,
                            labelFor: (p) => switch (p) {
                              QuranDashboardPeriod.daily =>
                                appText.daily.isNotEmpty
                                    ? appText.daily
                                    : 'Daily',
                              QuranDashboardPeriod.weekly =>
                                appText.weekly.isNotEmpty
                                    ? appText.weekly
                                    : 'Weekly',
                              QuranDashboardPeriod.monthly =>
                                appText.monthly.isNotEmpty
                                    ? appText.monthly
                                    : 'Monthly',
                            },
                            onChanged: (period, {month}) =>
                                _cubit.selectPeriod(period, month: month),
                          ),
                        ],
                      ),

                      SizedBox(height: 18.h),

                      // 3. Main Chart Canvas. Height follows the width, so the
                      // chart keeps its shape on every phone size.
                      AspectRatio(
                        aspectRatio: 1.4,
                        child: _buildChart(state, t),
                      ),

                      SizedBox(height: 24.h),

                      // 4. Summary Card 1: reading time over the period
                      QuranTotalReadingTimeCard(
                        readingTime: t.readingDuration(
                          state.history?.totals.totalSeconds ?? 0,
                        ),
                        label: t.totalReadingTimeFor(
                          days:
                              state.history?.days.length ??
                              kQuranReadingHistoryDays,
                          month: state.period == QuranDashboardPeriod.monthly
                              ? state.month
                              : null,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // 5. Summary Card 2: Most Reading Sura
                      QuranMostReadingSurahCard(
                        surahName: t.surahTitle(
                          t.surahName(
                            _mostReadSurah.number,
                            _mostReadSurah.name,
                          ),
                        ),
                        label: t.mostReadSurah,
                      ),

                      SizedBox(height: 16.h),

                      // 6. Today, the week, completion and "Continue reading"
                      _buildSummary(state, t, appText),

                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildSummary(
    QuranReadingDashboardState state,
    QuranText t,
    AppText appText,
  ) {
    final dashboard = state.dashboard;
    if (dashboard != null) {
      return QuranReadingSummary(dashboard: dashboard, onContinue: _continue);
    }
    return switch (state.status) {
      QuranReadingDashboardStatus.signedOut => QuranDashedCard(
        child: Text(
          t.signInToTrack,
          key: const ValueKey('quran-dashboard-sign-in'),
          textAlign: TextAlign.center,
        ),
      ),
      QuranReadingDashboardStatus.failure => QuranDashedCard(
        child: Column(
          children: [
            Text(
              state.failureMessage ?? appText.quranLoadError,
              textAlign: TextAlign.center,
            ),
            QuranRetry(onRetry: _cubit.load),
          ],
        ),
      ),
      QuranReadingDashboardStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  /// The user's (and the compared user's) minutes per day for the period.
  QuranChartData _chartData(QuranReadingDashboardState state, QuranText t) {
    final days = state.history?.days ?? const [];
    final competitor = state.comparison?.competitor;
    final theirs = competitor?.days ?? const <QuranDailyProgress>[];
    final monthly = state.period == QuranDashboardPeriod.monthly;
    return QuranChartData(
      labels: [
        for (final (i, day) in days.indexed)
          day.date == null
              ? t.n(i + 1)
              : monthly
              ? t.n(day.date!.day)
              : t.weekdayShort(day.date!),
      ],
      mine: [for (final day in days) day.readMinutes],
      competitor: theirs.length == days.length && theirs.isNotEmpty
          ? [for (final day in theirs) day.readMinutes]
          : null,
      competitorBadge: _initials(competitor),
    );
  }

  static String _initials(QuranComparedUser? user) {
    final words = (user?.name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    return words.map((word) => word.characters.first.toUpperCase()).join();
  }

  Widget _buildChart(QuranReadingDashboardState state, QuranText t) {
    switch (state.period) {
      case QuranDashboardPeriod.weekly:
        return QuranWeeklyChart(
          data: _chartData(state, t),
          showCompetitor: _showCompetitor,
        );

      case QuranDashboardPeriod.monthly:
        return QuranMonthlyChart(
          data: _chartData(state, t),
          controller: _monthlyScrollController,
          scrollProgress: _monthlyScrollProgress,
          showCompetitor: _showCompetitor,
        );

      case QuranDashboardPeriod.daily:
        final data = _chartData(state, t);
        final theirs = data.competitor;
        return QuranDailyChart(
          mine: data.mine.isEmpty ? 0 : data.mine.last,
          competitor: theirs == null || theirs.isEmpty ? null : theirs.last,
          competitorBadge: data.competitorBadge,
          showCompetitor: _showCompetitor,
        );
    }
  }
}
