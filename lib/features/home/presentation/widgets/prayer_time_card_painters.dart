part of 'prayer_time_card.dart';

class _PrayerArcPainter extends CustomPainter {
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

class _PrayerSunPainter extends CustomPainter {
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

class _PrayerBadgeIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final moonPaint = Paint()..color = const Color(0xFFFFC94C);
    final moon = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * .68, size.height * .27),
          radius: size.width * .18,
        ),
      );
    final cutout = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * .75, size.height * .21),
          radius: size.width * .17,
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, moon, cutout),
      moonPaint,
    );

    final leafPaint = Paint()..color = const Color(0xFF638664);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .13,
        size.height * .49,
        size.width * .47,
        size.height * .35,
      ),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .37,
        size.height * .57,
        size.width * .39,
        size.height * .27,
      ),
      leafPaint,
    );
    canvas.drawCircle(
      Offset(size.width * .18, size.height * .82),
      size.width * .10,
      Paint()..color = const Color(0xFFA5B653),
    );
    canvas.drawCircle(
      Offset(size.width * .80, size.height * .81),
      size.width * .11,
      Paint()..color = const Color(0xFFA5B653),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HorizonTimeIconPainter extends CustomPainter {
  const _HorizonTimeIconPainter({required this.isSunrise});

  final bool isSunrise;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8.r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final centerX = size.width / 2;
    final center = Offset(centerX, size.height * .48);
    final horizonY = size.height * .72;
    final sunRadius = size.width * .24;

    canvas.drawCircle(center, sunRadius, paint);
    canvas.drawLine(
      Offset(size.width * .09, horizonY),
      Offset(size.width * .91, horizonY),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * .2, horizonY + size.height * .11),
      Offset(size.width * .8, horizonY + size.height * .11),
      paint,
    );

    for (final angle in <double>[-2.75, -2.15, -math.pi / 2, -.99, -.39]) {
      final inner = Offset(
        center.dx + math.cos(angle) * size.width * .32,
        center.dy + math.sin(angle) * size.width * .32,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * size.width * .41,
        center.dy + math.sin(angle) * size.width * .41,
      );
      canvas.drawLine(inner, outer, paint);
    }

    final arrowTop = size.height * .35;
    final arrowBottom = size.height * .59;
    if (isSunrise) {
      canvas.drawLine(
        Offset(centerX, arrowBottom),
        Offset(centerX, arrowTop),
        paint,
      );
      canvas.drawLine(
        Offset(centerX, arrowTop),
        Offset(centerX - size.width * .09, arrowTop + size.height * .09),
        paint,
      );
      canvas.drawLine(
        Offset(centerX, arrowTop),
        Offset(centerX + size.width * .09, arrowTop + size.height * .09),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(centerX, arrowTop),
        Offset(centerX, arrowBottom),
        paint,
      );
      canvas.drawLine(
        Offset(centerX, arrowBottom),
        Offset(centerX - size.width * .09, arrowBottom - size.height * .09),
        paint,
      );
      canvas.drawLine(
        Offset(centerX, arrowBottom),
        Offset(centerX + size.width * .09, arrowBottom - size.height * .09),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HorizonTimeIconPainter oldDelegate) =>
      oldDelegate.isSunrise != isSunrise;
}


