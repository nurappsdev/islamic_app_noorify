import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_dashboard_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/amal_tracker_card_content.dart';

const _lineGreen = Color(0xFF9DAA55);
const _haloGreen = Color(0xFFCBD79B);

/// Content layer for the Nafl and more card. Draws no background of its own -
/// place it inside [HomeGradientShape]. Shares its header and title/counter
/// block with [AmalTrackerCardContent].
class NaflMoreCardContent extends StatelessWidget {
  const NaflMoreCardContent({
    super.key,
    this.percentage = 0,
    this.counter = '0/7',
    this.chartValues = defaultChartValues,
    this.onOpenDashboard,
  });

  /// Sample curve matching the design, 0-1 per point. Replace with real
  /// per-day values once the API provides them.
  static const defaultChartValues = [0.21, 0.20, 1.0, 0.0, 0.41, 0.32];

  /// 0-100.
  final num percentage;

  /// Points earned / max points, e.g. `0/7`.
  final String counter;

  /// Heights of the chart points, 0-1, spread evenly left to right.
  final List<double> chartValues;
  final VoidCallback? onOpenDashboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 28.h),
      child: Column(
        children: [
          ProgressHeaderWidget(
            percentage: percentage,
            onTap:
                onOpenDashboard ??
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AmolDashboardScreen(),
                  ),
                ),
          ),
          SizedBox(height: 26.h),
          PrayerSummaryWidget(title: 'Nafl and more', counter: counter),
          SizedBox(height: 18.h),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 22.w),
              child: CustomPaint(
                size: Size.infinite,
                painter: _CurveChartPainter(
                  values: chartValues,
                  dotRadius: 5.r,
                  haloRadius: 14.r,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Smooth area chart: each segment is a cubic with flat tangents at both
/// points (so peaks and dips stay round), a fading fill below, and a dot with
/// a soft halo on every point.
class _CurveChartPainter extends CustomPainter {
  const _CurveChartPainter({
    required this.values,
    required this.dotRadius,
    required this.haloRadius,
  });

  final List<double> values;
  final double dotRadius;
  final double haloRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    // Room for the halos so the highest and lowest points aren't clipped.
    final top = haloRadius;
    final bottom = size.height - haloRadius;
    final step = size.width / (values.length - 1);
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(i * step, bottom - values[i].clamp(0.0, 1.0) * (bottom - top)),
    ];

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final midX = (a.dx + b.dx) / 2;
      line.cubicTo(midX, a.dy, midX, b.dy, b.dx, b.dy);
    }

    final area = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _lineGreen.withValues(alpha: 0.85),
            _lineGreen.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6.r
        ..strokeCap = StrokeCap.round
        ..color = _lineGreen,
    );

    for (final p in points) {
      canvas.drawCircle(
        p,
        haloRadius,
        Paint()..color = _haloGreen.withValues(alpha: 0.7),
      );
      canvas.drawCircle(p, dotRadius + 1.5.r, Paint()..color = Colors.white);
      canvas.drawCircle(p, dotRadius, Paint()..color = _lineGreen);
      canvas.drawCircle(p, dotRadius * 0.45, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_CurveChartPainter old) =>
      old.values != values ||
      old.dotRadius != dotRadius ||
      old.haloRadius != haloRadius;
}
