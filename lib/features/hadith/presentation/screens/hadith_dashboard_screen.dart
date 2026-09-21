import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/repositories/hadith_library_repository_impl.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_comparison.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_read_records.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_reading_comparison.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_reading_history.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_comparison/hadith_comparison_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_dashboard/hadith_dashboard_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_read_records/hadith_read_records_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_bottom_nav.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_read_record_row.dart';

/// How many reading-history entries the dashboard previews.
const _recentPreviewCount = 3;

/// Hadith reading dashboard, reached from index 3 ("Dashboard") of the Hadith
/// navigation bar. Reading chart (`GET /learning/reading/history`) with a
/// daily / weekly / monthly filter, totals and recent history.
///
/// The chart plots the user's minutes read ("My Position"). Daily asks for
/// today only, weekly for the 7 days before today up to today, monthly for the
/// 30 days before today up to today.
///
/// The "My Nearest Or Competitor" toggle starts off. Switching it on loads
/// `GET /hadiths/reading/history/compare` for the same dates and draws the
/// other reader's minutes behind the user's.
class HadithDashboardScreen extends StatelessWidget {
  const HadithDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = HadithLibraryRepositoryImpl(
      HadithLibraryRemoteDataSourceImpl(),
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              HadithDashboardBloc(GetHadithReadingHistory(repository))
                ..add(const LoadHadithDashboard(HadithHistoryPeriod.daily)),
        ),
        // Loaded only once the competitor toggle is switched on.
        BlocProvider(
          create: (_) =>
              HadithComparisonBloc(GetHadithReadingComparison(repository)),
        ),
        // The reading history preview: just the 3 most recent. "See All" opens
        // the full, paginated list.
        BlocProvider(
          create: (_) => HadithReadRecordsBloc(
            GetHadithReadRecords(repository),
            pageSize: _recentPreviewCount,
          )..add(const LoadHadithReadRecords()),
        ),
      ],
      child: const _HadithDashboardView(),
    );
  }
}

class _HadithDashboardView extends StatefulWidget {
  const _HadithDashboardView();

  @override
  State<_HadithDashboardView> createState() => _HadithDashboardViewState();
}

class _HadithDashboardViewState extends State<_HadithDashboardView> {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Whether the second ("My Nearest Or Competitor") series is shown. Off at
  /// first, so the chart starts with only My Position and my own data.
  bool _showCompetitor = false;

  /// The point whose tooltip is open; null means the highest one.
  int? _selectedPoint;

  void _setCompetitor(bool value) {
    setState(() => _showCompetitor = value);
    if (value) {
      final dashboard = context.read<HadithDashboardBloc>().state;
      context.read<HadithComparisonBloc>().add(
        LoadHadithComparison(dashboard.period, month: dashboard.month),
      );
    }
  }

  /// A choice in the filter dropdown: a rolling [period] (Monthly is the last
  /// 30 days), or, with [month], that calendar month (grouped like Monthly).
  /// The competitor's dates follow when they are shown.
  void _selectFilter(HadithHistoryPeriod period, {DateTime? month}) {
    setState(() => _selectedPoint = null);
    context.read<HadithDashboardBloc>().add(
      LoadHadithDashboard(period, month: month),
    );
    if (_showCompetitor) {
      context.read<HadithComparisonBloc>().add(
        LoadHadithComparison(period, month: month),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<HadithDashboardBloc>().state;
    final comparison = context.watch<HadithComparisonBloc>().state;
    final history = state.history;

    // The other reader is drawn only while the toggle is on and their data is
    // for the dates on screen.
    final rival =
        _showCompetitor &&
            comparison.status == HadithComparisonStatus.success &&
            comparison.period == state.period &&
            comparison.month == state.month
        ? comparison.competitor
        : null;
    final series = _buildSeries(
      state,
      rival,
      // My initials come with the comparison, so only while it is shown.
      rival == null ? '' : hadithInitials(comparison.myName),
      appText.zikrTodaysValueGraph,
    );

    return BlocListener<HadithComparisonBloc, HadithComparisonState>(
      listenWhen: (previous, current) =>
          current.status == HadithComparisonStatus.failure,
      listener: (context, comparison) {
        // Couldn't load the other reader: say so, and switch the toggle back
        // off so turning it on again retries.
        setState(() => _showCompetitor = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(comparison.failure?.message ?? '')),
          );
      },
      child: _buildScaffold(
        context,
        appText,
        state,
        history,
        series,
        comparison,
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    AppText appText,
    HadithDashboardState state,
    HadithReadingHistory? history,
    _ChartSeries series,
    HadithComparisonState comparison,
  ) {
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 96.h),
              children: [
                SizedBox(height: 6.h),
                _Header(title: appText.dashboard),
                SizedBox(height: 18.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dark = my minutes read; light = the other reader's,
                          // loaded and drawn only while its toggle is on.
                          _LegendDot(
                            color: const Color(0xFF3F6B4E),
                            label: appText.myPosition,
                          ),
                          SizedBox(height: 6.h),
                          _LegendToggle(
                            color: const Color(0xFFA9B96A),
                            label: appText.myNearestOrCompetitor,
                            value: _showCompetitor,
                            loading: _showCompetitor && comparison.isLoading,
                            onChanged: _setCompetitor,
                          ),
                        ],
                      ),
                    ),
                    _PeriodDropdown(
                      period: state.period,
                      month: state.month,
                      labelFor: (period) => switch (period) {
                        HadithHistoryPeriod.daily => appText.daily,
                        HadithHistoryPeriod.weekly => appText.weekly,
                        HadithHistoryPeriod.monthly => appText.monthly,
                      },
                      onChanged: _selectFilter,
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                SizedBox(
                  height: 250.h,
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.status == HadithDashboardStatus.failure
                      ? _ChartError(
                          message: state.failure?.message ?? '',
                          retryLabel: appText.tryAgain,
                          onRetry: () =>
                              context.read<HadithDashboardBloc>().add(
                                LoadHadithDashboard(
                                  state.period,
                                  month: state.month,
                                ),
                              ),
                        )
                      : _ReadingChart(
                          series: series,
                          selectedIndex: _selectedPoint,
                          onSelect: (i) => setState(() => _selectedPoint = i),
                        ),
                ),
                SizedBox(height: 24.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: appText.totalReadingHadith,
                        value: history == null
                            ? '—'
                            : '${history.totals.hadithsRead}',
                        notes: [
                          if (history != null &&
                              history.totals.pointsText.isNotEmpty)
                            history.totals.pointsText,
                          if (history != null &&
                              history.totals.progressText.isNotEmpty)
                            history.totals.progressText,
                        ],
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: _StatCard(
                        label: appText.totalReadingTime,
                        value: history == null
                            ? '—'
                            : _formatMinutes(history.totals.totalMinutes),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 26.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appText.readingHistoryTitle,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(RouteNames.hadithReadingHistory),
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        appText.seeAll,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.inkColor(Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                const _RecentHistory(),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: HadithBottomNav(selectedIndex: 3),
            ),
          ],
        ),
      ),
    );
  }

  /// One point per calendar day of the requested range (days the backend
  /// left out count as 0). A single day (daily) is drawn as a peak between two
  /// zero points, captioned [todayCaption].
  static _ChartSeries _buildSeries(
    HadithDashboardState state,
    HadithCompetitor? rival,
    String myInitials,
    String todayCaption,
  ) {
    final from = state.from;
    final to = state.to;
    final history = state.history;
    if (from == null || to == null || history == null) {
      return const _ChartSeries(
        read: [0, 0],
        points: [null, null],
        labels: ['', ''],
      );
    }

    final dates = <DateTime>[];
    for (
      var d = from;
      !d.isAfter(to);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      dates.add(d);
    }

    // The points of the chart: each covers a run of days (start..end index).
    // Daily is the one day; weekly one point per day; monthly groups of 5
    // days so the chart stays readable — the last group ends today and takes
    // the leftover day (30 days back -> 6 groups, e.g. "16-21").
    final groups = <(int, int)>[];
    final labels = <String>[];
    switch (state.period) {
      case HadithHistoryPeriod.daily:
        groups.add((0, 0));
        labels.add(todayCaption);
      case HadithHistoryPeriod.weekly:
        for (var i = 0; i < dates.length; i++) {
          groups.add((i, i));
          labels.add(_weekdays[dates[i].weekday - 1]);
        }
      case HadithHistoryPeriod.monthly:
        const groupSize = 5;
        final count = math.max(1, (dates.length - 1) ~/ groupSize);
        for (var g = 0; g < count; g++) {
          final start = g * groupSize;
          final end = g == count - 1 ? dates.length - 1 : start + groupSize - 1;
          groups.add((start, end));
          labels.add('${dates[start].day}-${dates[end].day}');
        }
    }

    /// Minutes and points of [days] (by date) for every group; days the
    /// backend left out count as 0 minutes and no points.
    (List<double>, List<double?>) aggregate(List<HadithReadingDay> days) {
      final byDate = {for (final day in days) _dateKey(day.date): day};
      final minutes = <double>[];
      final points = <double?>[];
      for (final (start, end) in groups) {
        final slice = [
          for (var i = start; i <= end; i++) byDate[_dateKey(dates[i])],
        ];
        minutes.add(slice.fold(0, (sum, d) => sum + (d?.readMinutes ?? 0)));
        final pts = [for (final d in slice) ?d?.points];
        points.add(pts.isEmpty ? null : pts.fold<double>(0, (a, b) => a + b));
      }
      return (minutes, points);
    }

    var (read, points) = aggregate(history.days);
    final rivalSeries = rival == null ? null : aggregate(rival.days);
    var rivalRead = rivalSeries?.$1;
    var rivalPoints = rivalSeries?.$2;

    // A single point (daily, or a month with under 10 days so far) is drawn as
    // a peak between two zero points, and its points fall back to the range's
    // total when the day carries none.
    if (groups.length == 1) {
      points = [points.single ?? history.totals.totalPoints];
      List<T> peak<T>(List<T> one, T zero) => [zero, one.single, zero];
      read = peak(read, 0.0);
      points = peak(points, null);
      if (rivalRead != null && rivalPoints != null) {
        rivalRead = peak(rivalRead, 0.0);
        rivalPoints = peak(rivalPoints, null);
      }
      labels
        ..insert(0, '')
        ..add('');
    }

    return _ChartSeries(
      read: read,
      points: points,
      labels: labels,
      rival: rivalRead,
      rivalPoints: rivalPoints,
      rivalInitials: rival?.initials ?? '',
      myInitials: myInitials,
    );
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// `65 hr 32 min`, or just `32 min` under an hour.
  static String _formatMinutes(double minutes) {
    final total = minutes.round();
    final hours = total ~/ 60;
    final rest = total % 60;
    return hours == 0 ? '$rest min' : '$hours hr $rest min';
  }
}

/// What the chart draws, one entry per point in every list: my [read] minutes,
/// my [points] (null if unknown) and the x-axis [labels]. A point with an
/// empty label is not a real one (the zero padding around a single day) and
/// can't be selected.
///
/// [rival] / [rivalPoints] are the other reader's minutes and points at the
/// same points, or null while the competitor isn't shown; [rivalInitials]
/// tag their tooltip line.
class _ChartSeries {
  const _ChartSeries({
    required this.read,
    required this.points,
    required this.labels,
    this.rival,
    this.rivalPoints,
    this.rivalInitials = '',
    this.myInitials = '',
  });

  final List<double> read;
  final List<double?> points;
  final List<String> labels;
  final List<double>? rival;
  final List<double?>? rivalPoints;
  final String rivalInitials;

  /// My own initials for my tooltip; empty until the comparison has loaded.
  final String myInitials;
}

class _ChartError extends StatelessWidget {
  const _ChartError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            color: context.inkColor(const Color(0xFF5D6B44)),
          ),
        ),
        TextButton(onPressed: onRetry, child: Text(retryLabel)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFCBD16B),
                foregroundColor: context.inkColor(Color(0xFF303629)),
                minimumSize: Size(38.r, 38.r),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: context.inkColor(AppColor.authLogo),
              fontSize: 19.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
          width: 12.r,
          height: 12.r,
          decoration: BoxDecoration(
            color: context.surfaceColor(color),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5.sp,
              color: context.inkColor(Color(0xFF6A7350)),
            ),
          ),
        ),
      ],
    );
  }
}

/// A legend entry that also switches its chart series on and off. Greyed out
/// while off.
class _LegendToggle extends StatelessWidget {
  const _LegendToggle({
    required this.color,
    required this.label,
    required this.value,
    required this.onChanged,
    this.loading = false,
  });

  final Color color;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Shows a small spinner in place of the dot while the series is loading.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          SizedBox(
            width: 12.r,
            height: 12.r,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        else
          Container(
            width: 12.r,
            height: 12.r,
            decoration: BoxDecoration(
              color: context.surfaceColor(
                value ? color : const Color(0xFFCFD3C2),
              ),
              shape: BoxShape.circle,
            ),
          ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5.sp,
              color: context.inkColor(
                value ? const Color(0xFF6A7350) : const Color(0xFFA3A996),
              ),
            ),
          ),
        ),
        SizedBox(width: 4.w),
        Transform.scale(
          scale: .7,
          child: Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeThumbColor: Colors.white,
            activeTrackColor: color,
          ),
        ),
      ],
    );
  }
}

/// The filter button: Daily / Weekly / Monthly, and inside Monthly the 12
/// months. The button shows the picked month's name when there is one.
class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({
    required this.period,
    required this.month,
    required this.labelFor,
    required this.onChanged,
  });

  final HadithHistoryPeriod period;

  /// The picked month (first day), or null for the rolling periods.
  final DateTime? month;
  final String Function(HadithHistoryPeriod) labelFor;
  final void Function(HadithHistoryPeriod period, {DateTime? month}) onChanged;

  @override
  Widget build(BuildContext context) {
    final picked = month;
    return PopupMenuButton<void>(
      color: Colors.white,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      // One custom item: the menu handles its own taps, as choosing Monthly
      // must keep it open to show the months.
      itemBuilder: (_) => [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _PeriodMenu(
            period: period,
            month: month,
            labelFor: labelFor,
            onChanged: onChanged,
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(Color(0xFFDDE8BA)),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              picked == null ? labelFor(period) : _monthNames[picked.month - 1],
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: context.inkColor(Color(0xFF3E4A2A)),
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18.sp,
              color: context.inkColor(Color(0xFF3E4A2A)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The content of the filter menu. Daily and Weekly load and close it.
/// Monthly loads the last 30 days right away and stays open, expanding the 12
/// months of this year; a month loads and closes it.
class _PeriodMenu extends StatefulWidget {
  const _PeriodMenu({
    required this.period,
    required this.month,
    required this.labelFor,
    required this.onChanged,
  });

  final HadithHistoryPeriod period;
  final DateTime? month;
  final String Function(HadithHistoryPeriod) labelFor;
  final void Function(HadithHistoryPeriod period, {DateTime? month}) onChanged;

  @override
  State<_PeriodMenu> createState() => _PeriodMenuState();
}

class _PeriodMenuState extends State<_PeriodMenu> {
  // The menu route is separate from the screen, so it keeps its own copy of
  // the selection to stay right while it is open.
  late HadithHistoryPeriod _period = widget.period;
  late DateTime? _month = widget.month;

  /// Opens on the months when Monthly is already the active filter.
  late bool _monthsOpen = widget.period == HadithHistoryPeriod.monthly;

  void _pick(HadithHistoryPeriod period, {DateTime? month, bool close = true}) {
    setState(() {
      _period = period;
      _month = month;
    });
    widget.onChanged(period, month: month);
    if (close) Navigator.of(context).pop();
  }

  void _onMonthly() {
    final rollingMonthly =
        _period == HadithHistoryPeriod.monthly && _month == null;
    if (rollingMonthly) {
      // Already showing the last 30 days: just open or close the months.
      setState(() => _monthsOpen = !_monthsOpen);
    } else {
      // Monthly first (today back 30 days), then the months to narrow it.
      _pick(HadithHistoryPeriod.monthly, close: false);
      setState(() => _monthsOpen = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SizedBox(
      width: 220.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MenuRow(
            label: widget.labelFor(HadithHistoryPeriod.daily),
            active: _period == HadithHistoryPeriod.daily,
            onTap: () => _pick(HadithHistoryPeriod.daily),
          ),
          _MenuRow(
            label: widget.labelFor(HadithHistoryPeriod.weekly),
            active: _period == HadithHistoryPeriod.weekly,
            onTap: () => _pick(HadithHistoryPeriod.weekly),
          ),
          _MenuRow(
            label: widget.labelFor(HadithHistoryPeriod.monthly),
            active: _period == HadithHistoryPeriod.monthly,
            trailing: Icon(
              _monthsOpen
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20.sp,
              color: context.inkColor(const Color(0xFF3E4A2A)),
            ),
            onTap: _onMonthly,
          ),
          if (_monthsOpen)
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      '${now.year}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: context.inkColor(const Color(0xFF6A7350)),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      for (var m = 1; m <= 12; m++)
                        SizedBox(
                          width: 58.w,
                          height: 32.h,
                          child: _MonthChip(
                            name: _monthNames[m - 1].substring(0, 3),
                            // Months that haven't started have no data.
                            enabled: m <= now.month,
                            selected:
                                _month?.year == now.year && _month?.month == m,
                            onTap: () => _pick(
                              HadithHistoryPeriod.monthly,
                              month: DateTime(now.year, m),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.active,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        color: active ? const Color(0xFFEDF3D6) : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: context.inkColor(const Color(0xFF2C3320)),
                ),
              ),
            ),
            // The menu item is "disabled" (it handles its own taps), which
            // would dim icons; keep this one fully visible.
            if (trailing != null)
              IconTheme.merge(
                data: const IconThemeData(opacity: 1),
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// One month in the filter menu. Greyed out and inert when [enabled] is false.
class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.name,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.surfaceColor(
            selected ? const Color(0xFF3F6B4E) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: context.lineColor(
              selected ? const Color(0xFF3F6B4E) : const Color(0xFFC7D2A0),
            ),
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: selected
                ? Colors.white
                : context.inkColor(
                    enabled ? const Color(0xFF2C3320) : const Color(0xFFB4B9A6),
                  ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.notes = const [],
  });

  final String label;
  final String value;

  /// Small extra lines under the value (e.g. the backend's points text).
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 18.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: context.inkColor(Color(0xFF3B4430)),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: context.inkColor(Color(0xFF2C3320)),
              ),
            ),
            for (final note in notes) ...[
              SizedBox(height: 4.h),
              Text(
                note,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: context.inkColor(const Color(0xFF6A7350)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC7D2A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    final path = Path()..addRRect(rrect);
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The reading-history preview under the totals: the latest few hadiths read
/// (`GET /hadiths/reading/recent`), each with its sub-category and when it was
/// read. "See All" above it opens the full list.
class _RecentHistory extends StatelessWidget {
  const _RecentHistory();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<HadithReadRecordsBloc>().state;

    if (state.isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (state.status == HadithReadRecordsStatus.failure) {
      return Column(
        children: [
          Text(
            state.failure?.message ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: context.inkColor(const Color(0xFF5D6B44)),
            ),
          ),
          TextButton(
            onPressed: () => context.read<HadithReadRecordsBloc>().add(
              const LoadHadithReadRecords(),
            ),
            child: Text(appText.tryAgain),
          ),
        ],
      );
    }
    if (state.records.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Center(
          child: Text(
            appText.noResultsFound,
            style: TextStyle(
              fontSize: 13.sp,
              color: context.inkColor(const Color(0xFF5D6B44)),
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        // The bloc asks for exactly this many; take() is only a guard.
        for (final record in state.records.take(_recentPreviewCount)) ...[
          HadithReadRecordRow(record: record),
          Divider(height: 22.h, color: context.lineColor(Color(0xFFEDEFE0))),
        ],
      ],
    );
  }
}

/// Reading chart: my minutes read (dark, "my position") on a minutes axis,
/// with a tooltip on one point showing the points. Tap or drag to move the
/// tooltip; it starts on the highest point. While the competitor is shown
/// (`series.rival`), their minutes (light) are drawn behind mine and the
/// tooltip adds their points.
class _ReadingChart extends StatelessWidget {
  const _ReadingChart({
    required this.series,
    required this.selectedIndex,
    required this.onSelect,
  });

  final _ChartSeries series;

  /// The point whose tooltip is open; null means the highest one.
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  void _select(double dx, double width) {
    final i = _ReadingChartPainter.indexAt(dx, width, series.read.length);
    // The zero padding around a single day isn't a point.
    if (series.labels[i].isNotEmpty) onSelect(i);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _select(d.localPosition.dx, constraints.maxWidth),
        onHorizontalDragUpdate: (d) =>
            _select(d.localPosition.dx, constraints.maxWidth),
        child: CustomPaint(
          size: Size.infinite,
          painter: _ReadingChartPainter(
            series: series,
            selectedIndex: selectedIndex,
          ),
        ),
      ),
    );
  }
}

/// One reader's tooltip: its [text], the chart [point] it belongs to, and its
/// colours.
class _Bubble {
  const _Bubble(this.text, this.point, this.fill, this.ink);

  final String text;
  final Offset point;
  final Color fill;
  final Color ink;
}

class _ReadingChartPainter extends CustomPainter {
  _ReadingChartPainter({required this.series, required this.selectedIndex});

  final _ChartSeries series;
  final int? selectedIndex;

  static const _leftPad = 34.0;
  static const _rightPad = 6.0;

  /// The point nearest to horizontal position [dx] on a chart [width] wide.
  static int indexAt(double dx, double width, int count) {
    final chartWidth = width - _leftPad - _rightPad;
    final t = chartWidth <= 0 ? 0.0 : (dx - _leftPad) / chartWidth;
    return (t * (count - 1)).round().clamp(0, count - 1);
  }

  static const _readColor = Color(0xFF3F6B4E);
  static const _rivalColor = Color(0xFFA9B96A);
  static const _intervals = 4;

  /// A round step (1, 2, 5 x 10^n) so that [_intervals] of them cover [max].
  static double _niceStep(double max) {
    if (max <= 0) return 5; // nothing read and no goal: a small empty scale
    final raw = max / _intervals;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor());
    for (final factor in const [1, 2, 5, 10]) {
      final step = factor * magnitude.toDouble();
      if (step >= raw) return step;
    }
    return 10 * magnitude.toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final read = series.read;
    final rival = series.rival;
    final count = read.length;

    // Room above the top gridline for a tooltip sitting on the highest point.
    const topPad = 44.0;
    const bottomPad = 22.0; // room for x labels
    final chartLeft = _leftPad;
    final chartRight = size.width - _rightPad;
    final chartTop = topPad;
    final chartBottom = size.height - bottomPad;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    // A hidden competitor doesn't stretch the scale.
    final readPeak = read.reduce(math.max);
    final peak = rival == null
        ? readPeak
        : math.max(readPeak, rival.reduce(math.max));
    final step = _niceStep(peak);
    final maxY = step * _intervals;

    double xAt(int i) => chartLeft + chartWidth * (i / (count - 1));
    double yAt(double v) => chartBottom - chartHeight * (v / maxY);

    // Grid lines + Y labels.
    final gridPaint = Paint()
      ..color = const Color(0xFFECEFE1)
      ..strokeWidth = 1;
    for (var i = 0; i <= _intervals; i++) {
      final value = step * i;
      final y = yAt(value);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      _text(
        canvas,
        value == value.roundToDouble()
            ? '${value.round()}'
            : value.toStringAsFixed(1),
        Offset(chartLeft - 8, y),
        color: const Color(0xFF9AA279),
        fontSize: 9,
        align: TextAlign.right,
        anchorRight: true,
        anchorMiddleY: true,
      );
    }
    // The axis is in minutes (per day, or per 5-day group when monthly).
    _text(
      canvas,
      'min',
      Offset(chartLeft - 8, chartTop - 18),
      color: const Color(0xFF6A7350),
      fontSize: 10,
      align: TextAlign.right,
      anchorRight: true,
    );

    // X labels.
    for (var i = 0; i < series.labels.length; i++) {
      if (series.labels[i].isEmpty) continue;
      _text(
        canvas,
        series.labels[i],
        Offset(xAt(i), chartBottom + 6),
        color: const Color(0xFF6A7350),
        fontSize: 10,
        anchorCenterX: true,
      );
    }

    List<Offset> pointsOf(List<double> values) => [
      for (var i = 0; i < count; i++) Offset(xAt(i), yAt(values[i])),
    ];
    final rivalPoints = rival == null ? null : pointsOf(rival);
    final readPoints = pointsOf(read);

    // The other reader sits behind me: a smooth curve (img_37), except for a
    // single day, which is a plain peak like mine (img_36).
    if (rivalPoints != null) {
      _area(
        canvas,
        rivalPoints,
        _rivalColor,
        chartLeft,
        chartTop,
        chartRight,
        chartBottom,
        smooth: count > 3,
      );
    }
    _area(
      canvas,
      readPoints,
      _readColor,
      chartLeft,
      chartTop,
      chartRight,
      chartBottom,
    );

    // The tooltip's point: the one tapped, else my highest.
    final selected = _selected(readPeak);

    // Node markers on my line (a dot in a soft halo, as in img_37), only while
    // there are few enough; the selected point always gets a bigger one.
    for (var i = 0; i < count; i++) {
      final isSelected = i == selected;
      if (!isSelected && !(count > 3 && count <= 8)) continue;
      if (series.labels[i].isEmpty) continue;
      canvas.drawCircle(
        readPoints[i],
        isSelected ? 9 : 7.5,
        Paint()..color = _readColor.withValues(alpha: isSelected ? .28 : .18),
      );
      canvas.drawCircle(
        readPoints[i],
        isSelected ? 4.5 : 3.5,
        Paint()..color = _readColor,
      );
    }

    // Each reader has their own tooltip, on their own point of the chart: mine
    // (dark green) on my line, the competitor's (lime) on theirs. Only points
    // are shown — the date is already on the x axis and the minutes on the y
    // axis.
    final mineText = _pointsText(
      series.myInitials.isEmpty ? _myLabel : series.myInitials,
      series.points,
      selected,
    );
    final rivalText = series.rival == null
        ? null
        : _pointsText(series.rivalInitials, series.rivalPoints, selected);

    // The competitor's initials bubble above each of their other points, as in
    // the design; at the selected point their tooltip takes its place.
    if (rivalPoints != null && series.rivalInitials.isNotEmpty) {
      for (var i = 0; i < count; i++) {
        if (series.labels[i].isEmpty) continue;
        if (i == selected && rivalText != null) continue;
        _initialsBubble(
          canvas,
          size,
          Offset(rivalPoints[i].dx, rivalPoints[i].dy - 10),
          series.rivalInitials,
        );
      }
    }

    if (selected != null && series.labels[selected].isNotEmpty) {
      // A marker on the competitor's line too, so their tooltip visibly sits
      // on their own point, as mine does.
      if (rivalPoints != null) {
        canvas.drawCircle(
          rivalPoints[selected],
          9,
          Paint()..color = _rivalDark.withValues(alpha: .25),
        );
        canvas.drawCircle(
          rivalPoints[selected],
          4.5,
          Paint()..color = _rivalDark,
        );
      }
      _tooltips(canvas, size, [
        if (mineText != null)
          _Bubble(mineText, readPoints[selected], _readColor, Colors.white),
        if (rivalText != null && rivalPoints != null)
          _Bubble(
            rivalText,
            rivalPoints[selected],
            const Color(0xFFCDD891),
            const Color(0xFF2C3320),
          ),
      ]);
    }
  }

  /// What my tooltip says until my initials are known (the comparison hasn't
  /// loaded, e.g. the competitor toggle is off).
  static const _myLabel = 'MY';
  static const _rivalDark = Color(0xFF6C7A3C);

  /// `AB - 1 point` / `YA - 4 points` for point [selected]: the reader's
  /// initials and their own points; null when there is no such real point or
  /// its points are unknown.
  String? _pointsText(String who, List<double?>? points, int? selected) {
    if (selected == null || points == null) return null;
    if (series.labels[selected].isEmpty) return null;
    final value = points[selected];
    if (value == null) return null;
    return '$who - ${_number(value)} ${value == 1 ? 'point' : 'points'}';
  }

  /// The index whose tooltip is open: [selectedIndex] if still valid, else the
  /// highest point of my progress (none when nothing has been read).
  int? _selected(double readPeak) {
    final i = selectedIndex;
    if (i != null && i >= 0 && i < series.read.length) return i;
    return readPeak > 0 ? series.read.indexOf(readPeak) : null;
  }

  /// `45` for whole numbers, `45.5` otherwise.
  static String _number(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

  /// A filled area under a line through [points]: straight segments, or a
  /// smooth curve when [smooth].
  void _area(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double left,
    double top,
    double right,
    double bottom, {
    bool smooth = false,
  }) {
    final linePath = _linePath(points, smooth, top, bottom);
    final areaPath = Path.from(linePath)
      ..lineTo(points.last.dx, bottom)
      ..lineTo(points.first.dx, bottom)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .45), color.withValues(alpha: .12)],
        ).createShader(Rect.fromLTRB(left, top, right, bottom)),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  /// The line through [points]. Smooth ones are cubic segments whose control
  /// points are kept between [top] and [bottom], so the curve never dips under
  /// the baseline or over the top.
  Path _linePath(List<Offset> points, bool smooth, double top, double bottom) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (!smooth || points.length < 3) {
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }
    double clampY(double y) => y.clamp(top, bottom).toDouble();
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[math.max(i - 1, 0)];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[math.min(i + 2, points.length - 1)];
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        clampY(p1.dy + (p2.dy - p0.dy) / 6),
        p2.dx - (p3.dx - p1.dx) / 6,
        clampY(p2.dy - (p3.dy - p1.dy) / 6),
        p2.dx,
        p2.dy,
      );
    }
    return path;
  }

  /// The small "• Ab" pill of the design: a dot and the other reader's
  /// [initials], sitting on [anchor] and kept inside the chart.
  void _initialsBubble(
    Canvas canvas,
    Size size,
    Offset anchor,
    String initials,
  ) {
    const h = 22.0;
    final tp = _layout(initials, const Color(0xFF3E4A2A), 10);
    final w = tp.width + 26;
    final left = (anchor.dx - w / 2)
        .clamp(0.0, math.max(0.0, size.width - w))
        .toDouble();
    final rect = Rect.fromLTWH(left, math.max(0.0, anchor.dy - h), w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(11)),
      Paint()..color = const Color(0xFFCDD891),
    );
    canvas.drawCircle(
      Offset(rect.left + 11, rect.center.dy),
      3,
      Paint()..color = const Color(0xFF6C7A3C),
    );
    tp.paint(canvas, Offset(rect.left + 18, rect.center.dy - tp.height / 2));
  }

  /// Draws one tooltip per reader, each on its own point: above it, like the
  /// design. When the two points are so close that the bubbles would collide,
  /// they move apart sideways — one to the left of the point, the other to the
  /// right — instead of sharing one spot. All are kept inside the chart.
  void _tooltips(Canvas canvas, Size size, List<_Bubble> bubbles) {
    if (bubbles.isEmpty) return;
    const padX = 10.0;
    const height = 24.0;
    const above = 12.0; // gap between a point and the bubble over it
    const beside = 10.0; // gap between a point and the bubble next to it

    final painters = [for (final b in bubbles) _layout(b.text, b.ink, 10.5)];
    final widths = [for (final p in painters) p.width + padX * 2];

    Rect place(double left, double top, int i) => Rect.fromLTWH(
      left.clamp(0.0, math.max(0.0, size.width - widths[i])).toDouble(),
      math.max(0.0, top),
      widths[i],
      height,
    );
    Rect over(int i) => place(
      bubbles[i].point.dx - widths[i] / 2,
      bubbles[i].point.dy - above - height,
      i,
    );
    Rect leftOf(int i) => place(
      bubbles[i].point.dx - beside - widths[i],
      bubbles[i].point.dy - height / 2,
      i,
    );
    Rect rightOf(int i) => place(
      bubbles[i].point.dx + beside,
      bubbles[i].point.dy - height / 2,
      i,
    );

    var rects = [for (var i = 0; i < bubbles.length; i++) over(i)];
    if (bubbles.length == 2 && rects[0].overlaps(rects[1])) {
      // Both points share the tapped x. Mine goes left and theirs right — or
      // the other way round at a chart edge where that doesn't fit.
      final x = bubbles[0].point.dx;
      final split = [leftOf(0), rightOf(1)];
      final fits = split[0].right <= x - 4 && split[1].left >= x + 4;
      rects = fits ? split : [rightOf(0), leftOf(1)];
    }

    for (var i = 0; i < bubbles.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rects[i], const Radius.circular(12)),
        Paint()..color = bubbles[i].fill,
      );
      painters[i].paint(
        canvas,
        Offset(
          rects[i].left + padX,
          rects[i].center.dy - painters[i].height / 2,
        ),
      );
    }
  }

  TextPainter _layout(
    String text,
    Color color,
    double fontSize, {
    TextAlign align = TextAlign.left,
  }) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    ),
    textAlign: align,
    textDirection: TextDirection.ltr,
  )..layout();

  void _text(
    Canvas canvas,
    String text,
    Offset offset, {
    required Color color,
    required double fontSize,
    TextAlign align = TextAlign.left,
    bool anchorRight = false,
    bool anchorCenterX = false,
    bool anchorMiddleY = false,
  }) {
    final tp = _layout(text, color, fontSize, align: align);
    var dx = offset.dx;
    if (anchorRight) dx -= tp.width;
    if (anchorCenterX) dx -= tp.width / 2;
    var dy = offset.dy;
    if (anchorMiddleY) dy -= tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _ReadingChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.selectedIndex != selectedIndex;
}
