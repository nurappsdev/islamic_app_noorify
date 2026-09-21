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
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_reading_history.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_dashboard/hadith_dashboard_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_bottom_nav.dart';

/// Hadith reading dashboard, reached from index 3 ("Dashboard") of the Hadith
/// navigation bar. Reading chart (`GET /learning/reading/history`) with a
/// daily / weekly / monthly filter, totals and recent history.
///
/// The chart plots the minutes read (progress) against the daily goal in
/// minutes. Daily asks for today only, weekly for the 7 days before today up
/// to today, monthly for the 30 days before today up to today.
class HadithDashboardScreen extends StatelessWidget {
  const HadithDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HadithDashboardBloc(
        GetHadithReadingHistory(
          HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl()),
        ),
      )..add(const LoadHadithDashboard(HadithHistoryPeriod.daily)),
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

  /// Whether the second ("My Nearest Or Competitor") series is drawn. Off at
  /// first, so the chart starts with only My Position.
  bool _showCompetitor = false;

  /// The point whose tooltip is open; null means the highest one.
  int? _selectedPoint;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<HadithDashboardBloc>().state;
    final history = state.history;
    final series = _buildSeries(state, appText.zikrTodaysValueGraph);

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
                          // Dark = minutes read (my progress); light = the goal,
                          // drawn only while its toggle is on.
                          _LegendDot(
                            color: const Color(0xFF3F6B4E),
                            label: appText.myPosition,
                          ),
                          SizedBox(height: 6.h),
                          _LegendToggle(
                            color: const Color(0xFFA9B96A),
                            label: appText.myNearestOrCompetitor,
                            value: _showCompetitor,
                            onChanged: (value) =>
                                setState(() => _showCompetitor = value),
                          ),
                        ],
                      ),
                    ),
                    _PeriodDropdown(
                      selected: state.period,
                      labelFor: (period) => switch (period) {
                        HadithHistoryPeriod.daily => appText.daily,
                        HadithHistoryPeriod.weekly => appText.weekly,
                        HadithHistoryPeriod.monthly => appText.monthly,
                      },
                      onSelected: (period) {
                        setState(() => _selectedPoint = null);
                        context.read<HadithDashboardBloc>().add(
                          LoadHadithDashboard(period),
                        );
                      },
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
                          onRetry: () => context
                              .read<HadithDashboardBloc>()
                              .add(LoadHadithDashboard(state.period)),
                        )
                      : _ReadingChart(
                          series: series,
                          showGoal: _showCompetitor,
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
                for (final entry in const [
                  ('Hadith', '17 Aug  At 5 : 35 PM'),
                  ('E-book', '17 Aug  At 5 : 35 PM'),
                  ('Hadith', '17 Aug  At 5 : 35 PM'),
                ]) ...[
                  _HistoryRow(label: entry.$1, timestamp: entry.$2),
                  Divider(
                    height: 22.h,
                    color: context.lineColor(Color(0xFFEDEFE0)),
                  ),
                ],
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
    String todayCaption,
  ) {
    final from = state.from;
    final to = state.to;
    final history = state.history;
    if (from == null || to == null || history == null) {
      return const _ChartSeries(
        read: [0, 0],
        goal: [0, 0],
        points: [null, null],
        labels: ['', ''],
      );
    }
    final byDate = {for (final day in history.days) _dateKey(day.date): day};

    final dates = <DateTime>[];
    for (
      var d = from;
      !d.isAfter(to);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      dates.add(d);
    }
    final days = [for (final d in dates) byDate[_dateKey(d)]];

    double? sumPoints(Iterable<HadithReadingDay?> ds) {
      final values = [for (final d in ds) ?d?.points];
      return values.isEmpty ? null : values.fold<double>(0, (a, b) => a + b);
    }

    // Daily: the one day, drawn as a peak between two zero points. Its points
    // fall back to the range's total when the day carries none.
    if (dates.length == 1) {
      return _ChartSeries(
        read: [0, days.single?.readMinutes ?? 0, 0],
        goal: [0, days.single?.goalMinutes ?? 0, 0],
        points: [null, days.single?.points ?? history.totals.totalPoints, null],
        labels: ['', todayCaption, ''],
      );
    }

    // Monthly: groups of 5 days, so the chart stays readable. The last group
    // ends today and takes the leftover day (30 days back -> 6 groups, e.g.
    // "16 - 21 Sep").
    if (state.period == HadithHistoryPeriod.monthly) {
      const groupSize = 5;
      final groups = math.max(1, (dates.length - 1) ~/ groupSize);
      final read = <double>[];
      final goal = <double>[];
      final points = <double?>[];
      final labels = <String>[];
      for (var g = 0; g < groups; g++) {
        final start = g * groupSize;
        final end = g == groups - 1 ? dates.length - 1 : start + groupSize - 1;
        final slice = days.sublist(start, end + 1);
        read.add(slice.fold(0, (sum, d) => sum + (d?.readMinutes ?? 0)));
        goal.add(slice.fold(0, (sum, d) => sum + (d?.goalMinutes ?? 0)));
        points.add(sumPoints(slice));
        // "16-21": the group's days; the tooltip carries only the points.
        labels.add('${dates[start].day}-${dates[end].day}');
      }
      return _ChartSeries(
        read: read,
        goal: goal,
        points: points,
        labels: labels,
      );
    }

    // Weekly: one point per day.
    return _ChartSeries(
      read: [for (final d in days) d?.readMinutes ?? 0],
      goal: [for (final d in days) d?.goalMinutes ?? 0],
      points: [for (final d in days) d?.points],
      labels: [for (final d in dates) _weekdays[d.weekday - 1]],
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

/// What the chart draws, one entry per point in every list: [read] minutes
/// (the progress), [goal] minutes, the [points] earned (null if unknown), the
/// x-axis [labels]. A point with an empty label is not a real one (the zero
/// padding around a single day) and can't be selected.
class _ChartSeries {
  const _ChartSeries({
    required this.read,
    required this.goal,
    required this.points,
    required this.labels,
  });

  final List<double> read;
  final List<double> goal;
  final List<double?> points;
  final List<String> labels;
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
  });

  final Color color;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final HadithHistoryPeriod selected;
  final String Function(HadithHistoryPeriod) labelFor;
  final ValueChanged<HadithHistoryPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<HadithHistoryPeriod>(
      onSelected: onSelected,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      itemBuilder: (context) => [
        for (final period in HadithHistoryPeriod.values)
          PopupMenuItem(value: period, child: Text(labelFor(period))),
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
              labelFor(selected),
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

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.label, required this.timestamp});

  final String label;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32.r,
          height: 32.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.lineColor(Color(0xFFE3E7D3))),
          ),
          child: Icon(
            Icons.menu_book_outlined,
            size: 15.sp,
            color: context.inkColor(Color(0xFF8B9865)),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: context.inkColor(Color(0xFF2C3320)),
          ),
        ),
        const Spacer(),
        Text(
          timestamp,
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFFA1AD59)),
        ),
      ],
    );
  }
}

/// Reading chart: the minutes read (dark, "my position") on a minutes axis,
/// with a tooltip on one point showing its period, points and minutes. Tap or
/// drag to move the tooltip; it starts on the highest point. With [showGoal],
/// the goal minutes (light) are drawn behind it.
class _ReadingChart extends StatelessWidget {
  const _ReadingChart({
    required this.series,
    required this.showGoal,
    required this.selectedIndex,
    required this.onSelect,
  });

  final _ChartSeries series;
  final bool showGoal;

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
            showGoal: showGoal,
            selectedIndex: selectedIndex,
          ),
        ),
      ),
    );
  }
}

class _ReadingChartPainter extends CustomPainter {
  _ReadingChartPainter({
    required this.series,
    required this.showGoal,
    required this.selectedIndex,
  });

  final _ChartSeries series;
  final bool showGoal;
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
  static const _goalColor = Color(0xFFA9B96A);
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
    final goal = series.goal;
    final count = read.length;

    // Room above the top gridline for the one-line tooltip.
    const topPad = 44.0;
    const bottomPad = 22.0; // room for x labels
    final chartLeft = _leftPad;
    final chartRight = size.width - _rightPad;
    final chartTop = topPad;
    final chartBottom = size.height - bottomPad;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    // A hidden goal doesn't stretch the scale.
    final readPeak = read.reduce(math.max);
    final goalPeak = goal.reduce(math.max);
    final peak = showGoal ? math.max(readPeak, goalPeak) : readPeak;
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
    final goalPoints = pointsOf(goal);
    final readPoints = pointsOf(read);

    // The goal sits behind the progress.
    if (showGoal) {
      _area(
        canvas,
        goalPoints,
        _goalColor,
        chartLeft,
        chartTop,
        chartRight,
        chartBottom,
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

    // Node markers on the progress line, only while there are few enough;
    // the selected point always gets one.
    for (var i = 0; i < count; i++) {
      final isSelected = i == selected;
      if (!isSelected && !(count > 3 && count <= 8)) continue;
      if (series.labels[i].isEmpty) continue;
      final radius = isSelected ? 6.5 : 5.0;
      canvas.drawCircle(readPoints[i], radius, Paint()..color = Colors.white);
      canvas.drawCircle(
        readPoints[i],
        radius,
        Paint()
          ..color = isSelected ? _readColor : const Color(0xFF8FA08A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    // The tooltip shows only the points: the date is already on the x axis and
    // the minutes on the y axis. Nothing when the points are unknown.
    final points = selected == null ? null : series.points[selected];
    if (selected != null &&
        series.labels[selected].isNotEmpty &&
        points != null) {
      // Above the higher of the lines that are showing.
      final top = showGoal
          ? math.min(readPoints[selected].dy, goalPoints[selected].dy)
          : readPoints[selected].dy;
      _tooltip(canvas, size, Offset(readPoints[selected].dx, top - 12), [
        ('${_number(points)} points', true),
      ]);
    }
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

  void _area(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double left,
    double top,
    double right,
    double bottom,
  ) {
    final areaPath = Path()..moveTo(points.first.dx, bottom);
    for (final p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath
      ..lineTo(points.last.dx, bottom)
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

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  /// A rounded tooltip of text [lines] — (text, emphasised) — sitting on
  /// [anchor], kept inside the chart.
  void _tooltip(
    Canvas canvas,
    Size size,
    Offset anchor,
    List<(String, bool)> lines,
  ) {
    const padX = 10.0;
    const padY = 6.0;
    final painters = [
      for (final (text, strong) in lines)
        _layout(
          text,
          strong ? const Color(0xFF2C3320) : const Color(0xFF5D6B44),
          strong ? 11 : 9.5,
        ),
    ];
    final w = painters.map((p) => p.width).reduce(math.max) + padX * 2;
    final h = painters.fold<double>(0, (sum, p) => sum + p.height) + padY * 2;
    final left = (anchor.dx - w / 2)
        .clamp(0.0, math.max(0.0, size.width - w))
        .toDouble();
    final top = math.max(0.0, anchor.dy - h);
    final rect = Rect.fromLTWH(left, top, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..color = const Color(0xFFCDD891),
    );
    var y = rect.top + padY;
    for (final p in painters) {
      p.paint(canvas, Offset(rect.left + padX, y));
      y += p.height;
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
      oldDelegate.showGoal != showGoal ||
      oldDelegate.selectedIndex != selectedIndex;
}
