import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_bottom_nav.dart';

/// Dua reading dashboard, with Daily, Weekly and Monthly visual summaries
/// from `devImg/img.png`, `img_1.png`, and `img_2.png`.
///
/// The reading analytics API is not available in the Dua module yet, so the
/// chart values mirror the approved design data. The period picker and layout
/// are ready to receive live values when that endpoint is connected.
class DuaAnalyticsDashboardScreen extends StatefulWidget {
  const DuaAnalyticsDashboardScreen({super.key});

  @override
  State<DuaAnalyticsDashboardScreen> createState() =>
      _DuaAnalyticsDashboardScreenState();
}

class _DuaAnalyticsDashboardScreenState
    extends State<DuaAnalyticsDashboardScreen> {
  _DuaDashboardPeriod _period = _DuaDashboardPeriod.daily;

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
                _DashboardHeader(
                  period: _period,
                  onChanged: (period) => setState(() => _period = period),
                ),
                SizedBox(height: 12.h),
                const _PositionSummary(),
                SizedBox(height: 14.h),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: switch (_period) {
                    _DuaDashboardPeriod.daily => const _DailyChart(
                      key: ValueKey('daily'),
                    ),
                    _DuaDashboardPeriod.weekly => const _WeeklyChart(
                      key: ValueKey('weekly'),
                    ),
                    _DuaDashboardPeriod.monthly => const _MonthlyChart(
                      key: ValueKey('monthly'),
                    ),
                  },
                ),
                SizedBox(height: 16.h),
                _Metrics(period: _period),
                SizedBox(height: 20.h),
                _HistoryHeader(title: appText.duaIntroTitle),
                SizedBox(height: 8.h),
                const _RecitationHistory(),
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

  String get duration => switch (this) {
    _DuaDashboardPeriod.daily => '3h 45m',
    _DuaDashboardPeriod.weekly => '72h 45m',
    _DuaDashboardPeriod.monthly => '744h 45m',
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
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.of(
              context,
            ).pushReplacementNamed(RouteNames.duaDashboard),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFE6E77D),
              foregroundColor: const Color(0xFF4C5631),
              minimumSize: Size(34.r, 34.r),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
          ),
        ),
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
  const _PositionSummary();

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
        const _PercentagePill(value: '68%'),
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
        const _PercentagePill(value: '32%', muted: true),
      ],
    ),
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 9.r,
    height: 9.r,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
      color: muted ? const Color(0xFFC2CF92) : const Color(0xFFA6B65B),
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
  const _DailyChart({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 205.h,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(size: Size(184.w, 184.w), painter: const _DonutPainter()),
        Positioned(top: 12.h, right: 0, child: const _ChartTooltip()),
      ],
    ),
  );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: size.width * .34);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .17
      ..strokeCap = StrokeCap.round;
    paint.color = const Color(0xFFDCE8B5);
    canvas.drawArc(rect, -math.pi * .88, math.pi * 1.34, false, paint);
    paint.color = const Color(0xFFA8B657);
    canvas.drawArc(rect, math.pi * .47, math.pi * 1.18, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChartTooltip extends StatelessWidget {
  const _ChartTooltip();

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
      'Abdullah Al-Aziz\n\nTime : 23 min\n\nPoint : 1.5/1.0',
      style: TextStyle(
        color: context.inkColor(const Color(0xFF364027)),
        fontSize: 9.sp,
        height: 1.05,
      ),
    ),
  );
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({super.key});

  @override
  Widget build(BuildContext context) {
    const values = [40, 75, 85, 100, 40, 75, 92];
    const labels = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
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
                for (final label in const ['1000', '750', '500', '250', '0'])
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: const Color(0xFF91A168),
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
                for (var index = 0; index < values.length; index++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: values[index] / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: index == 2 || index == 3
                                        ? const Color(0xFFA8B657)
                                        : const Color(0xFFD6E4AA),
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
                            labels[index],
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

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({super.key});

  @override
  Widget build(BuildContext context) {
    const values = [.84, .36, .32, .88];
    const labels = ['28-31', '21', '14', '7'];
    return SizedBox(
      height: 205.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var index = 0; index < values.length; index++)
            Row(
              children: [
                SizedBox(
                  width: 34.w,
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF91A168),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SizedBox(
                    height: 24.h,
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          widthFactor: .94,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3EDC3),
                              borderRadius: BorderRadius.circular(7.r),
                            ),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: values[index],
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFA8B657),
                              borderRadius: BorderRadius.circular(7.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.only(left: 48.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final day in const [
                  'Sat',
                  'Sun',
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                ])
                  Text(day, style: TextStyle(fontSize: 10.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.period});
  final _DuaDashboardPeriod period;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: _MetricCard(
          title: 'Total Duas Recited',
          value: '148',
          subtitle: 'Daily Target: 35/40',
          colors: [Color(0xFF782CEB), Color(0xFF5245D7)],
        ),
      ),
      SizedBox(width: 12.w),
      Expanded(
        child: _MetricCard(
          title: 'Dua Recitation Time',
          value: period.duration,
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
  const _HistoryHeader({required this.title});
  final String title;

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
      Column(
        children: [
          Text(
            'See All',
            style: TextStyle(color: const Color(0xFF98A46C), fontSize: 11.sp),
          ),
          Container(width: 49.w, height: 1.h, color: const Color(0xFF98A46C)),
        ],
      ),
    ],
  );
}

class _RecitationHistory extends StatelessWidget {
  const _RecitationHistory();

  @override
  Widget build(BuildContext context) => Column(
    children: const [
      _HistoryRow(
        icon: Icons.wb_sunny_outlined,
        title: 'Morning Dua',
        subtitle: 'Alhamdulillahil... • 1 Dua',
        time: '17 Aug At 5:35 AM',
        duration: '8 mins read',
      ),
      _HistoryRow(
        icon: Icons.location_on_outlined,
        title: 'Waking Supplication',
        subtitle: 'Alhamdulillahi... • 1 Dua',
        time: '17 Aug At 6:15 AM',
        duration: '3 mins read',
      ),
      _HistoryRow(
        icon: Icons.shield_outlined,
        title: 'Protection & Ruqyah Duas',
        subtitle: 'Falaq, Nas & Ayat al-Kursi • 7 Duas',
        time: '16 Aug At 9:20 PM',
        duration: '15 mins read',
      ),
    ],
  );
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
            border: Border.all(color: const Color(0xFFC7D590)),
          ),
          child: Icon(icon, color: const Color(0xFFA6B65B), size: 17.sp),
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
                  color: const Color(0xFF778060),
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
                  color: const Color(0xFF97A64D),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                duration,
                style: TextStyle(
                  fontSize: 8.sp,
                  color: const Color(0xFF778060),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
