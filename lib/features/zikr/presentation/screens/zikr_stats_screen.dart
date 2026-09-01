import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/zikr/presentation/widgets/zikr_bottom_nav.dart';

/// Zikr stats dashboard (designs `devImg/img_25.png` and `devImg/img_26.png`),
/// reached from index 2 ("Dashboard") of [ZikrBottomNav].
///
/// UI only — every number and the chart are mock data. The period toggle swaps
/// a "Daily" single-peak graph for a "Weekly" 7-day line.
class ZikrStatsScreen extends StatefulWidget {
  const ZikrStatsScreen({super.key});

  @override
  State<ZikrStatsScreen> createState() => _ZikrStatsScreenState();
}

class _ZikrStatsScreenState extends State<ZikrStatsScreen> {
  int _period = 0; // 0 = Daily, 1 = Weekly

  static const _weekly = <double>[490, 690, 880, 240, 250, 760, 180];
  static const _weekDays = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  static const _history = <(String, String)>[
    ('Subhan Allah', '450'),
    ('Alhamdulillah', '312'),
    ('Allahu Akbar', '198'),
  ];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final isDaily = _period == 0;

    return Scaffold(
      backgroundColor: Colors.white,
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
                      value: isDaily ? appText.daily : appText.weekly,
                      daily: appText.daily,
                      weekly: appText.weekly,
                      onSelected: (i) => setState(() => _period = i),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                SizedBox(
                  height: 250.h,
                  child: _StatsChart(
                    values: isDaily ? const [0, 900, 0] : _weekly,
                    labels: isDaily
                        ? ['', appText.zikrTodaysValueGraph, '']
                        : _weekDays,
                    bubbleAll: !isDaily,
                    competitorInitials: appText.competitorInitials,
                    daily: isDaily,
                  ),
                ),
                SizedBox(height: 22.h),
                _TotalPill(
                  label: '${appText.zikrTotalZikr} : 780',
                  trailing: '854',
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: appText.zikrTotalZikr,
                        value: '132,765',
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: _StatCard(
                        label: appText.zikrMostDoing,
                        value: 'Subhan-Allah  34,784',
                        italicValue: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appText.zikrHistory,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      appText.seeAll,
                      style: TextStyle(fontSize: 12.sp, color: Colors.black),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                for (final entry in _history) ...[
                  _HistoryRow(name: entry.$1, count: entry.$2),
                  Divider(height: 22.h, color: const Color(0xFFEDEFE0)),
                ],
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: ZikrBottomNav(selectedIndex: 2),
            ),
          ],
        ),
      ),
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
                foregroundColor: const Color(0xFF303629),
                minimumSize: Size(38.r, 38.r),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColor.authLogo,
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5.sp, color: const Color(0xFF6A7350)),
          ),
        ),
      ],
    );
  }
}

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({
    required this.value,
    required this.onSelected,
    required this.daily,
    required this.weekly,
  });

  final String value;
  final ValueChanged<int> onSelected;
  final String daily;
  final String weekly;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: onSelected,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      itemBuilder: (context) => [
        PopupMenuItem(value: 0, child: Text(daily)),
        PopupMenuItem(value: 1, child: Text(weekly)),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFDDE8BA),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3E4A2A),
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18.sp,
              color: const Color(0xFF3E4A2A),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalPill extends StatelessWidget {
  const _TotalPill({required this.label, required this.trailing});

  final String label;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFDDE8C1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE8BA),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3E4A2A),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Row(
              children: [
                Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA9B96A),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6A7350),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.italicValue = false,
  });

  final String label;
  final String value;
  final bool italicValue;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 18.h, 14.w, 18.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF3B4430)),
            ),
            SizedBox(height: 16.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontStyle: italicValue ? FontStyle.italic : FontStyle.normal,
                color: const Color(0xFF2C3320),
              ),
            ),
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
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      );
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
  const _HistoryRow({required this.name, required this.count});

  final String name;
  final String count;

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
            border: Border.all(color: const Color(0xFFE3E7D3)),
          ),
          child: Icon(
            Icons.self_improvement_rounded,
            size: 16.sp,
            color: const Color(0xFF8B9865),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          name,
          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF2C3320)),
        ),
        const Spacer(),
        Text(
          count,
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFFA1AD59)),
        ),
      ],
    );
  }
}

/// Area-line chart: "Weekly" draws a 7-point line with an "Ab" bubble over every
/// node; "Daily" draws a single peak with one bubble.
class _StatsChart extends StatelessWidget {
  const _StatsChart({
    required this.values,
    required this.labels,
    required this.bubbleAll,
    required this.competitorInitials,
    required this.daily,
  });

  final List<double> values;
  final List<String> labels;
  final bool bubbleAll;
  final String competitorInitials;
  final bool daily;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _StatsChartPainter(
        values: values,
        labels: labels,
        bubbleAll: bubbleAll,
        competitorInitials: competitorInitials,
        daily: daily,
      ),
    );
  }
}

class _StatsChartPainter extends CustomPainter {
  _StatsChartPainter({
    required this.values,
    required this.labels,
    required this.bubbleAll,
    required this.competitorInitials,
    required this.daily,
  });

  final List<double> values;
  final List<String> labels;
  final bool bubbleAll;
  final String competitorInitials;
  final bool daily;

  static const _maxY = 1000.0;
  static const _steps = [0, 250, 500, 750, 1000];

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const topPad = 44.0;
    const bottomPad = 22.0;
    final chartLeft = leftPad;
    final chartRight = size.width - 6;
    final chartTop = topPad;
    final chartBottom = size.height - bottomPad;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    double xAt(int i) => chartLeft + chartWidth * (i / (values.length - 1));
    double yAt(double v) => chartBottom - chartHeight * (v / _maxY);

    final gridPaint = Paint()
      ..color = const Color(0xFFECEFE1)
      ..strokeWidth = 1;
    for (final step in _steps) {
      final y = yAt(step.toDouble());
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      _text(
        canvas,
        '$step',
        Offset(chartLeft - 8, y),
        color: const Color(0xFF9AA279),
        fontSize: 9,
        anchorRight: true,
        anchorMiddleY: true,
      );
    }

    for (var i = 0; i < labels.length; i++) {
      if (labels[i].isEmpty) continue;
      _text(
        canvas,
        labels[i],
        Offset(xAt(i), chartBottom + 6),
        color: const Color(0xFF6A7350),
        fontSize: 10,
        anchorCenterX: true,
      );
    }

    final points = [
      for (var i = 0; i < values.length; i++) Offset(xAt(i), yAt(values[i])),
    ];

    final areaPath = Path()..moveTo(points.first.dx, chartBottom);
    for (final p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath
      ..lineTo(points.last.dx, chartBottom)
      ..close();
    final fill = daily
        ? const [Color(0x66A6C97E), Color(0x11A6C97E)]
        : const [Color(0x559BA7D8), Color(0x0F9BA7D8)];
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: fill,
            ).createShader(
              Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom),
            ),
    );

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF3A4A2E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (daily && values[i] == 0) continue;
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..color = const Color(0xFF8FA08A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      if (bubbleAll || (daily && values[i] > 0)) {
        _bubble(canvas, size, Offset(p.dx, p.dy - 16));
      }
    }
  }

  void _bubble(Canvas canvas, Size size, Offset anchor) {
    const w = 42.0;
    const h = 22.0;
    var left = anchor.dx - w / 2;
    left = left.clamp(0.0, size.width - w);
    final rect = Rect.fromLTWH(left, anchor.dy - h, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(11)),
      Paint()..color = const Color(0xFFCDD891),
    );
    canvas.drawCircle(
      Offset(rect.left + 12, rect.center.dy),
      3,
      Paint()..color = const Color(0xFF6C7A3C),
    );
    _text(
      canvas,
      competitorInitials,
      Offset(rect.left + 19, rect.center.dy),
      color: const Color(0xFF3E4A2A),
      fontSize: 10,
      anchorMiddleY: true,
    );
  }

  void _text(
    Canvas canvas,
    String text,
    Offset offset, {
    required Color color,
    required double fontSize,
    bool anchorRight = false,
    bool anchorCenterX = false,
    bool anchorMiddleY = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = offset.dx;
    if (anchorRight) dx -= tp.width;
    if (anchorCenterX) dx -= tp.width / 2;
    var dy = offset.dy;
    if (anchorMiddleY) dy -= tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _StatsChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.labels != labels ||
      oldDelegate.daily != daily;
}
