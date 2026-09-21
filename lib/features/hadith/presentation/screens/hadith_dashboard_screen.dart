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

class _HadithDashboardView extends StatelessWidget {
  const _HadithDashboardView();

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
                          // Dark = minutes read (progress); light = the goal.
                          _LegendDot(
                            color: const Color(0xFF3F6B4E),
                            label: appText.myPosition,
                          ),
                          SizedBox(height: 10.h),
                          _LegendDot(
                            color: const Color(0xFFA9B96A),
                            label: appText.myNearestOrCompetitor,
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
                      onSelected: (period) => context
                          .read<HadithDashboardBloc>()
                          .add(LoadHadithDashboard(period)),
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
                      : _ReadingChart(series: series),
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
      return const _ChartSeries(read: [0, 0], goal: [0, 0], labels: ['', '']);
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
    final read = [for (final d in dates) byDate[_dateKey(d)]?.readMinutes ?? 0];
    final goal = [for (final d in dates) byDate[_dateKey(d)]?.goalMinutes ?? 0];

    if (dates.length == 1) {
      return _ChartSeries(
        read: [0, read.single, 0],
        goal: [0, goal.single, 0],
        labels: ['', todayCaption, ''],
      );
    }
    return _ChartSeries(
      read: read,
      goal: goal,
      labels: [
        for (var i = 0; i < dates.length; i++)
          if (state.period == HadithHistoryPeriod.weekly)
            _weekdays[dates[i].weekday - 1]
          // Monthly has too many days to label each one.
          else if (i % 5 == 0)
            '${dates[i].day}'
          else
            '',
      ],
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

/// What the chart draws: [read] minutes (the progress) and [goal] minutes per
/// point, with an x-axis [labels] entry per point ('' for none).
class _ChartSeries {
  const _ChartSeries({
    required this.read,
    required this.goal,
    required this.labels,
  });

  final List<double> read;
  final List<double> goal;
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

/// Reading chart: two filled area lines — the goal minutes (light) behind the
/// minutes read (dark) — with a bubble on the goal's peak.
class _ReadingChart extends StatelessWidget {
  const _ReadingChart({required this.series});

  final _ChartSeries series;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _ReadingChartPainter(series: series),
    );
  }
}

class _ReadingChartPainter extends CustomPainter {
  _ReadingChartPainter({required this.series});

  final _ChartSeries series;

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

    const leftPad = 34.0;
    const topPad = 44.0; // room for the goal bubble
    const bottomPad = 22.0; // room for x labels
    final chartLeft = leftPad;
    final chartRight = size.width - 6;
    final chartTop = topPad;
    final chartBottom = size.height - bottomPad;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final peak = math.max(read.reduce(math.max), goal.reduce(math.max));
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
    _area(
      canvas,
      goalPoints,
      _goalColor,
      chartLeft,
      chartTop,
      chartRight,
      chartBottom,
    );
    _area(
      canvas,
      readPoints,
      _readColor,
      chartLeft,
      chartTop,
      chartRight,
      chartBottom,
    );

    // Node markers on the progress line, only while there are few enough.
    if (count > 3 && count <= 8) {
      for (final p in readPoints) {
        canvas.drawCircle(p, 5, Paint()..color = Colors.white);
        canvas.drawCircle(
          p,
          5,
          Paint()
            ..color = const Color(0xFF8FA08A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
    }

    // Bubble on the goal's highest point, with the goal in minutes.
    final goalPeak = goal.reduce(math.max);
    if (goalPeak > 0) {
      final peakIndex = goal.indexOf(goalPeak);
      _bubble(
        canvas,
        size,
        Offset(goalPoints[peakIndex].dx, goalPoints[peakIndex].dy - 10),
        '${goalPeak.round()} min',
      );
    }
  }

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

  void _bubble(Canvas canvas, Size size, Offset anchor, String label) {
    const h = 22.0;
    final tp = _layout(label, const Color(0xFF3E4A2A), 10);
    final w = tp.width + 32;
    final left = (anchor.dx - w / 2).clamp(0.0, size.width - w);
    final rect = Rect.fromLTWH(left, anchor.dy - h, w, h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(11));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFCDD891));
    canvas.drawCircle(
      Offset(rect.left + 12, rect.center.dy),
      3,
      Paint()..color = const Color(0xFF6C7A3C),
    );
    tp.paint(canvas, Offset(rect.left + 19, rect.center.dy - tp.height / 2));
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
      oldDelegate.series != series;
}
