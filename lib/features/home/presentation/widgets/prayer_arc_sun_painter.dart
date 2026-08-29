import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Renders the day-progress arc together with the sun positioned along it,
/// both driven by [progress] — the fraction (0..1) of daylight elapsed
/// between sunrise and sunset.
class PrayerDayProgress extends StatelessWidget {
  const PrayerDayProgress({super.key, required this.progress});

  final double progress;

  static const _strokeWidth = 10.0;
  static const _sunDiameter = 43.0;

  @override
  Widget build(BuildContext context) {
    final strokeWidth = _strokeWidth.r;
    final sunDiameter = _sunDiameter.r;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final sunCenter = _sunCenterFor(size, progress, strokeWidth);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: size,
              painter: PrayerArcPainter(
                progress: progress,
                strokeWidth: strokeWidth,
              ),
            ),
            Positioned(
              left: sunCenter.dx - sunDiameter / 2,
              top: sunCenter.dy - sunDiameter / 2,
              child: SizedBox.square(
                dimension: sunDiameter,
                child: const CustomPaint(painter: PrayerSunPainter()),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Mirrors the ellipse [PrayerArcPainter] strokes: centered at the box's
  /// bottom-middle, spanning its full width and height.
  static Offset _sunCenterFor(Size size, double progress, double strokeWidth) {
    final radiusX = (size.width - strokeWidth) / 2;
    final radiusY = size.height;
    final angle = math.pi + math.pi * progress.clamp(0.0, 1.0);
    return Offset(
      size.width / 2 + radiusX * math.cos(angle),
      size.height + radiusY * math.sin(angle),
    );
  }
}

class PrayerArcPainter extends CustomPainter {
  const PrayerArcPainter({required this.progress, required this.strokeWidth});

  /// Fraction (0..1) of daylight elapsed between sunrise and sunset.
  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      0,
      size.width - strokeWidth,
      size.height * 2,
    );
    final basePaint = Paint()
      ..color = const Color(0xFFECE9D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = const Color(0xFF5D8067)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, basePaint);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * progress.clamp(0.0, 1.0),
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant PrayerArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class PrayerSunPainter extends CustomPainter {
  const PrayerSunPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rayPaint = Paint()
      ..color = const Color(0xFFFFA328)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .09;

    for (var index = 0; index < 8; index++) {
      final angle = index * math.pi / 4;
      final inner = Offset(
        center.dx + math.cos(angle) * size.width * .34,
        center.dy + math.sin(angle) * size.width * .34,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * size.width * .45,
        center.dy + math.sin(angle) * size.width * .45,
      );
      canvas.drawLine(inner, outer, rayPaint);
    }

    canvas.drawCircle(
      center,
      size.width * .23,
      Paint()..color = const Color(0xFFFFA328),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
