import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bottom_nav.dart';

/// Dua reading dashboard, with Daily, Weekly and Monthly visual summaries
/// from `devImg/img.png`, `img_1.png`, and `img_2.png`.
///
/// Its existing approved layout is populated from the reading dashboard API.
class DuaAnalyticsDashboardScreen extends StatefulWidget {
  const DuaAnalyticsDashboardScreen({super.key});

  @override
  State<DuaAnalyticsDashboardScreen> createState() =>
      _DuaAnalyticsDashboardScreenState();
}

class _DuaAnalyticsDashboardScreenState
    extends State<DuaAnalyticsDashboardScreen> {
  _DuaDashboardPeriod _period = _DuaDashboardPeriod.daily;
  DuaReadingDashboard? _dashboard;
  Object? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dashboard = await duaRepository.getReadingDashboard(
        timeframe: _period.name,
      );
      if (!mounted) return;
      setState(() => _dashboard = dashboard);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changePeriod(_DuaDashboardPeriod period) {
    if (_period == period) return;
    setState(() => _period = period);
    _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16.w,
                6.h,
                16.w,
                112.h + bottomInset,
              ),
              children: [
                _DashboardHeader(period: _period, onChanged: _changePeriod),
                SizedBox(height: 12.h),
                if (_loading) const LinearProgressIndicator(minHeight: 2),
                if (_error != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: TextButton(
                      onPressed: _loadDashboard,
                      child: const Text('Unable to load dashboard. Retry'),
                    ),
                  ),
                _PositionSummary(dashboard: _dashboard),
                SizedBox(height: 14.h),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: switch (_period) {
                    _DuaDashboardPeriod.daily => _DailyChart(
                      key: ValueKey('daily'),
                      dashboard: _dashboard,
                    ),
                    _DuaDashboardPeriod.weekly => _WeeklyChart(
                      key: ValueKey('weekly'),
                      dashboard: _dashboard,
                    ),
                    _DuaDashboardPeriod.monthly => _MonthlyChart(
                      key: ValueKey('monthly'),
                      dashboard: _dashboard,
                    ),
                  },
                ),
                SizedBox(height: 16.h),
                _Metrics(period: _period, dashboard: _dashboard),
                SizedBox(height: 20.h),
                _HistoryHeader(
                  title: appText.duaIntroTitle,
                  onSeeAll: () => Navigator.of(
                    context,
                  ).pushNamed(RouteNames.duaRecitationHistory),
                ),
                SizedBox(height: 8.h),
                _RecitationHistory(
                  items: _dashboard?.recentRecitations ?? const [],
                ),
              ],
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

enum _DuaDashboardPeriod { daily, weekly, monthly }

extension on _DuaDashboardPeriod {
  String get label => switch (this) {
    _DuaDashboardPeriod.daily => 'Daily',
    _DuaDashboardPeriod.weekly => 'Weekly',
    _DuaDashboardPeriod.monthly => 'Monthly',
  };
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.period, required this.onChanged});

  final _DuaDashboardPeriod period;
  final ValueChanged<_DuaDashboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44.h,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Text(
          AppText.of(context).dashboard,
          style: TextStyle(
            color: context.inkColor(const Color(0xFF83915E)),
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: PopupMenuButton<_DuaDashboardPeriod>(
            onSelected: onChanged,
            initialValue: period,
            color: context.surfaceColor(Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
            itemBuilder: (_) => [
              for (final value in _DuaDashboardPeriod.values)
                PopupMenuItem(value: value, child: Text(value.label)),
            ],
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: context.surfaceColor(const Color(0xFFE0EABD)),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(period.label, style: TextStyle(fontSize: 12.sp)),
                  SizedBox(width: 4.w),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18.sp),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PositionSummary extends StatelessWidget {
  const _PositionSummary({this.dashboard});

  final DuaReadingDashboard? dashboard;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
    decoration: BoxDecoration(
      color: context.surfaceColor(const Color(0xFFF5F8E8)),
      borderRadius: BorderRadius.circular(10.r),
    ),
    child: Row(
      children: [
        const _LegendDot(color: Color(0xFFACB955)),
        SizedBox(width: 5.w),
        Text(
          'My Position',
          style: TextStyle(
            color: context.inkColor(const Color(0xFF97A64D)),
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 8.w),
        _PercentagePill(value: _percentage(dashboard?.myPositionPercentage)),
        const Spacer(),
        const _LegendDot(color: Color(0xFFF0EEC1)),
        SizedBox(width: 5.w),
        Text(
          'Competitor',
          style: TextStyle(
            color: context.inkColor(const Color(0xFF687484)),
            fontSize: 12.sp,
          ),
        ),
        SizedBox(width: 8.w),
        _PercentagePill(
          value: _percentage(dashboard?.competitorPercentage),
          muted: true,
        ),
      ],
    ),
  );
}

String _percentage(double? value) => value == null ? '—' : '${value.round()}%';

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
  final String value;
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
      value,
      style: TextStyle(
        color: Colors.white,
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({super.key, this.dashboard});

  final DuaReadingDashboard? dashboard;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 205.h,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(184.w, 184.w),
          painter: _DonutPainter(
            trackColor: context.surfaceColor(const Color(0xFFDCE8B5)),
            progressColor: context.surfaceColor(const Color(0xFFA8B657)),
            progress: ((dashboard?.myPositionPercentage ?? 0) / 100).clamp(
              0.0,
              1.0,
            ),
          ),
        ),
        Positioned(
          top: 12.h,
          right: 0,
          child: _ChartTooltip(dashboard: dashboard),
        ),
      ],
    ),
  );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.trackColor,
    required this.progressColor,
    required this.progress,
  });

  final Color trackColor;
  final Color progressColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: size.width * .34);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .17
      ..strokeCap = StrokeCap.round;
    paint.color = trackColor;
    canvas.drawArc(rect, -math.pi * .88, math.pi * 1.34, false, paint);
    paint.color = progressColor;
    canvas.drawArc(
      rect,
      math.pi * .47,
      math.pi * 1.34 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.progress != progress;
}

class _ChartTooltip extends StatelessWidget {
  const _ChartTooltip({this.dashboard});

  final DuaReadingDashboard? dashboard;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
    decoration: BoxDecoration(
      color: context.surfaceColor(const Color(0xFFE6EEC6)),
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .18),
          blurRadius: 9.r,
          offset: Offset(0, 3.h),
        ),
      ],
    ),
    child: Text(
      'Time : ${dashboard?.totalReadingTimeFormatted ?? '—'}\n\n'
      'Duas : ${dashboard?.totalDuasRecited ?? '—'}',
      style: TextStyle(
        color: context.inkColor(const Color(0xFF364027)),
        fontSize: 9.sp,
        height: 1.05,
      ),
    ),
  );
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({super.key, this.dashboard});

  final DuaReadingDashboard? dashboard;

  @override
  Widget build(BuildContext context) {
    final activity = dashboard?.activity ?? const <DuaDashboardActivityDay>[];
    final highest = activity.fold<int>(
      0,
      (value, item) => math.max(value, item.minutes),
    );
    return SizedBox(
      height: 205.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 7.h, bottom: 26.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final label in const ['100', '75', '50', '25', '0'])
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: context.textInkColor(const Color(0xFF91A168)),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < activity.length; index++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: highest == 0
                                    ? 0
                                    : activity[index].minutes / highest,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: context.surfaceColor(
                                      activity[index].duas > 0
                                          ? const Color(0xFFA8B657)
                                          : const Color(0xFFD6E4AA),
                                    ),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(7.r),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            activity[index].label,
                            style: TextStyle(fontSize: 10.sp),
                          ),
                        ],
                      ),
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

class _MonthlyChart extends StatefulWidget {
  const _MonthlyChart({super.key, this.dashboard});

  final DuaReadingDashboard? dashboard;

  @override
  State<_MonthlyChart> createState() => _MonthlyChartState();
}

class _MonthlyChartState extends State<_MonthlyChart> {
  int? _selectedBar;

  @override
  Widget build(BuildContext context) {
    final activity =
        widget.dashboard?.activity ?? const <DuaDashboardActivityDay>[];
    final points = [for (final item in activity) item.minutes];
    final labels = [for (final item in activity) item.label];
    final highest = points.fold<int>(0, math.max);
    return SizedBox(
      height: 218.h,
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var index = 0; index < points.length; index++)
                Row(
                  children: [
                    SizedBox(
                      width: 44.w,
                      child: Text(
                        labels[index],
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: context.textInkColor(const Color(0xFF91A168)),
                        ),
                      ),
                    ),
                    SizedBox(width: 9.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedBar = index),
                        child: SizedBox(
                          height: 24.h,
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: context.surfaceColor(
                                      const Color(0xFFE3EDC3),
                                    ),
                                    borderRadius: BorderRadius.circular(7.r),
                                  ),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: highest == 0
                                    ? 0
                                    : points[index] / highest,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  decoration: BoxDecoration(
                                    color: context.surfaceColor(
                                      _selectedBar == index
                                          ? const Color(0xFF718E3B)
                                          : const Color(0xFFA8B657),
                                    ),
                                    borderRadius: BorderRadius.circular(7.r),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: EdgeInsets.only(left: 53.w, right: 2.w, top: 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final point in [
                      0,
                      highest ~/ 5,
                      highest * 2 ~/ 5,
                      highest * 3 ~/ 5,
                      highest * 4 ~/ 5,
                      highest,
                    ])
                      Text(
                        '$point',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: context.textInkColor(const Color(0xFF758052)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedBar case final index?)
            Positioned(
              top: 3.h,
              right: 6.w,
              child: _MonthlyCompetitorTooltip(points: points[index]),
            ),
        ],
      ),
    );
  }
}

class _MonthlyCompetitorTooltip extends StatelessWidget {
  const _MonthlyCompetitorTooltip({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
    decoration: BoxDecoration(
      color: context.surfaceColor(const Color(0xFFE6EEC6)),
      borderRadius: BorderRadius.circular(12.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .18),
          blurRadius: 9.r,
          offset: Offset(0, 3.h),
        ),
      ],
    ),
    child: Text(
      'Reading activity\nMinutes: $points',
      style: TextStyle(
        color: context.inkColor(const Color(0xFF364027)),
        fontSize: 9.sp,
        height: 1.35,
      ),
    ),
  );
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.period, this.dashboard});
  final _DuaDashboardPeriod period;
  final DuaReadingDashboard? dashboard;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _MetricCard(
          title: 'Total Duas Recited',
          value: '${dashboard?.totalDuasRecited ?? '—'}',
          subtitle: dashboard?.dailyTargetText.isNotEmpty == true
              ? 'Daily Target: ${dashboard!.dailyTargetText}'
              : 'Daily Target: —',
          colors: const [Color(0xFF782CEB), Color(0xFF5245D7)],
        ),
      ),
      SizedBox(width: 12.w),
      Expanded(
        child: _MetricCard(
          title: 'Dua Recitation Time',
          value: dashboard?.totalReadingTimeFormatted ?? '—',
          subtitle: 'Total recitation time',
          colors: const [Color(0xFF08BCEB), Color(0xFF2365DD)],
        ),
      ),
    ],
  );
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
          style: TextStyle(color: Colors.white, fontSize: 10.sp),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 23.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          subtitle,
          style: TextStyle(color: Colors.white, fontSize: 8.sp),
        ),
      ],
    ),
  );
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.title, required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          'Dua Recitation History',
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
            children: [
              Text(
                'See All',
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

class _RecitationHistory extends StatelessWidget {
  const _RecitationHistory({required this.items});

  final List<DuaReadingHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Text(
          'No recitation history yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.sp,
            color: context.textInkColor(const Color(0xFF778060)),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final item in items.take(3))
          _HistoryRow(
            icon: Icons.menu_book_outlined,
            title: context.localized(item.title),
            subtitle: _historySubtitle(context, item),
            time: _historyTime(context, item),
            duration: _historyDuration(item),
          ),
      ],
    );
  }
}

String _historySubtitle(BuildContext context, DuaReadingHistoryItem item) {
  final category = context.localized(item.category);
  if (category.isNotEmpty) return category;
  return item.arabic;
}

String _historyTime(BuildContext context, DuaReadingHistoryItem item) {
  if (item.timeAgoText.isNotEmpty) return item.timeAgoText;
  final time = item.lastReadAt?.toLocal();
  if (time == null) return '—';
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatShortDate(time)} ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(time))}';
}

String _historyDuration(DuaReadingHistoryItem item) {
  if (item.readSeconds <= 0) {
    return item.readCount > 0 ? '${item.readCount} Dua' : '—';
  }
  final minutes = (item.readSeconds / 60).ceil();
  return '$minutes min read';
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.duration,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final String duration;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 10.h),
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
            icon,
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
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
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
          width: 90.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 8.5.sp,
                  color: context.textInkColor(const Color(0xFF97A64D)),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                duration,
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
