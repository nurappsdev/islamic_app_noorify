import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrayerArcPainter extends CustomPainter {
  const PrayerArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 10.r;
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

    canvas.drawArc(rect, 3.14, 3.14, false, basePaint);
    canvas.drawArc(rect, 3.14, 2.32, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
