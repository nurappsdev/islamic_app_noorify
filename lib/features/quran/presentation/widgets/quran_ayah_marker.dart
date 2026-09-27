import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';

/// Draw the ornament inside explicit bounds: Quran-font bracket glyphs can
/// paint outside their advance width and overlap adjacent Arabic words.
class QuranAyahMarker extends StatelessWidget {
  const QuranAyahMarker({super.key, required this.number, required this.scale});
  final int number;
  final double scale;
  @override
  Widget build(BuildContext context) {
    final color = context.inkColor(Colors.black);
    final size = 28.0 * scale;
    final digits = number
        .toString()
        .split('')
        .map((digit) => String.fromCharCode(0x660 + int.parse(digit)))
        .join();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale),
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _Ornament(color),
          child: Center(
            child: Text(
              digits,
              textDirection: TextDirection.ltr,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: 'Noorehuda',
                fontSize: 12 * scale,
                height: 1,
                color: color,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Ornament extends CustomPainter {
  const _Ornament(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()..color = color;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .44;
    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        size.shortestSide * .024,
        pen,
      );
    }
  }

  @override
  bool shouldRepaint(_Ornament oldDelegate) => oldDelegate.color != color;
}
