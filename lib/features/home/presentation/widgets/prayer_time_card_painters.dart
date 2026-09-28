part of 'prayer_time_card.dart';

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
