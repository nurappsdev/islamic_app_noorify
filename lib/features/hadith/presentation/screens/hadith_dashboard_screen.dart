import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_bottom_nav.dart';

/// Hadith reading dashboard, reached from index 3 ("Dashboard") of the Hadith
/// navigation bar. Weekly reading chart, totals and recent history.
class HadithDashboardScreen extends StatefulWidget {
  const HadithDashboardScreen({super.key});

  @override
  State<HadithDashboardScreen> createState() => _HadithDashboardScreenState();
}

class _HadithDashboardScreenState extends State<HadithDashboardScreen> {
  int _period = 0; // 0 = weekly, 1 = monthly

  static const _weekly = <double>[520, 790, 970, 300, 320, 780, 250];
  static const _weekDays = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  static const _monthly = <double>[430, 610, 540, 880, 700, 950, 610];
  static const _monthWeeks = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7'];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final values = _period == 0 ? _weekly : _monthly;
    final labels = _period == 0 ? _weekDays : _monthWeeks;

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
                      value: _period == 0 ? appText.weekly : appText.monthly,
                      onSelected: (i) => setState(() => _period = i),
                      weekly: appText.weekly,
                      monthly: appText.monthly,
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                SizedBox(
                  height: 250.h,
                  child: _ReadingChart(
                    values: values,
                    labels: labels,
                    competitorInitials: appText.competitorInitials,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: appText.totalReadingHadith,
                        value: '765',
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: _StatCard(
                        label: appText.totalReadingTime,
                        value: '65  hr 32 min',
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
                        style: TextStyle(fontSize: 12.sp, color: Colors.black),
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
                  Divider(height: 22.h, color: const Color(0xFFEDEFE0)),
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
            style: TextStyle(
              fontSize: 12.5.sp,
              color: const Color(0xFF6A7350),
            ),
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
    required this.weekly,
    required this.monthly,
  });

  final String value;
  final ValueChanged<int> onSelected;
  final String weekly;
  final String monthly;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: onSelected,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      itemBuilder: (context) => [
        PopupMenuItem(value: 0, child: Text(weekly)),
        PopupMenuItem(value: 1, child: Text(monthly)),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

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
                color: const Color(0xFF3B4430),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
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
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
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
            border: Border.all(color: const Color(0xFFE3E7D3)),
          ),
          child: Icon(
            Icons.menu_book_outlined,
            size: 15.sp,
            color: const Color(0xFF8B9865),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF2C3320),
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

/// Weekly reading chart: filled area line with node markers and a competitor
/// "Ab" bubble above every point.
class _ReadingChart extends StatelessWidget {
  const _ReadingChart({
    required this.values,
    required this.labels,
    required this.competitorInitials,
  });

  final List<double> values;
  final List<String> labels;
  final String competitorInitials;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _ReadingChartPainter(
        values: values,
        labels: labels,
        competitorInitials: competitorInitials,
      ),
    );
  }
}

class _ReadingChartPainter extends CustomPainter {
  _ReadingChartPainter({
    required this.values,
    required this.labels,
    required this.competitorInitials,
  });

  final List<double> values;
  final List<String> labels;
  final String competitorInitials;

  static const _maxY = 1000.0;
  static const _steps = [0, 250, 500, 750, 1000];

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const topPad = 44.0; // room for the "Ab" bubbles
    const bottomPad = 22.0; // room for x labels
    final chartLeft = leftPad;
    final chartRight = size.width - 6;
    final chartTop = topPad;
    final chartBottom = size.height - bottomPad;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    double xAt(int i) =>
        chartLeft + chartWidth * (i / (values.length - 1));
    double yAt(double v) => chartBottom - chartHeight * (v / _maxY);

    // Grid lines + Y labels.
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
        align: TextAlign.right,
        anchorRight: true,
        anchorMiddleY: true,
      );
    }

    // X labels.
    for (var i = 0; i < labels.length; i++) {
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

    // Filled area.
    final areaPath = Path()..moveTo(points.first.dx, chartBottom);
    for (final p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath
      ..lineTo(points.last.dx, chartBottom)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x559BA7D8), Color(0x0F9BA7D8)],
        ).createShader(Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom)),
    );

    // Line.
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

    // Node markers + competitor bubbles.
    for (final p in points) {
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..color = const Color(0xFF8FA08A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      _bubble(canvas, size, Offset(p.dx, p.dy - 16));
    }
  }

  void _bubble(Canvas canvas, Size size, Offset anchor) {
    const w = 42.0;
    const h = 22.0;
    var left = anchor.dx - w / 2;
    left = left.clamp(0.0, size.width - w);
    final rect = Rect.fromLTWH(left, anchor.dy - h, w, h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(11));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFCDD891));
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
    TextAlign align = TextAlign.left,
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
      textAlign: align,
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
  bool shouldRepaint(covariant _ReadingChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.labels != labels;
}
