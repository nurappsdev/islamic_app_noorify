import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:islami_app_noorify/core/theme/app_palette.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';

/// A compass rose that points at the Kaaba (design `img_40.png` /
/// `img_41.png`).
///
/// [qiblahAngle] is the Qiblah bearing in degrees clockwise from true north
/// (0-360, as returned by the dashboard API). [heading] is the device's
/// current compass heading in the same system; the whole rose rotates by
/// `-heading` so its printed "N" tracks true north the way a physical
/// compass card does. Pass `heading: 0` for a static preview.
class QiblahCompassDial extends StatelessWidget {
  const QiblahCompassDial({
    super.key,
    required this.qiblahAngle,
    this.heading = 0,
    this.size = 200,
  });

  final double qiblahAngle;
  final double heading;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final headingRad = heading * math.pi / 180;
    final qiblahRad = qiblahAngle * math.pi / 180;
    final markerRadius = size / 2 * 0.76;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outermost soft halo, the way img_40/img_41 fade the dial into
          // the page instead of hard-edging it.
          Container(
            width: size * 1.34,
            height: size * 1.34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColor.primary.withValues(alpha: 0.16),
                  AppColor.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          // Glassy face: a lit outer disc over a dimmer, smaller inner disc
          // fakes the embossed/layered look of the reference dial.
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColor.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Container(
            width: size * 0.66,
            height: size * 0.66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.tintSoft.withValues(alpha: 0.6),
            ),
          ),
          Transform.rotate(
            angle: -headingRad,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(size),
                  painter: _CompassFacePainter(
                    qiblahAngleRad: qiblahRad,
                    ringColor: palette.border,
                    tickColor: palette.textPrimary.withValues(alpha: 0.4),
                    labelColor: palette.textPrimary.withValues(alpha: 0.65),
                    needleColor: AppColor.primary,
                  ),
                ),
                Transform.translate(
                  offset: Offset(
                    markerRadius * math.sin(qiblahRad),
                    -markerRadius * math.cos(qiblahRad),
                  ),
                  // Counter-rotate so the Kaaba glyph itself stays upright
                  // while its position still orbits with the dial.
                  child: Transform.rotate(
                    angle: headingRad,
                    child: _KaabaBadge(size: size * 0.16),
                  ),
                ),
              ],
            ),
          ),
          _CenterSpark(size: size * 0.07, color: AppColor.primary),
        ],
      ),
    );
  }
}

/// The small 4-point sparkle at the rose's pivot (design's center mark,
/// rather than a plain dot).
class _CenterSpark extends StatelessWidget {
  const _CenterSpark({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _SparkPainter(color));
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _KaabaBadge extends StatelessWidget {
  const _KaabaBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Image.asset('assets/kakbah.png', fit: BoxFit.contain),
    );
  }
}

class _CompassFacePainter extends CustomPainter {
  _CompassFacePainter({
    required this.qiblahAngleRad,
    required this.ringColor,
    required this.tickColor,
    required this.labelColor,
    required this.needleColor,
  });

  final double qiblahAngleRad;
  final Color ringColor;
  final Color tickColor;
  final Color labelColor;
  final Color needleColor;

  static const _cardinals = ['N', 'E', 'S', 'W'];
  static const _northColor = Color(0xFFD1523B);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    for (var deg = 0; deg < 360; deg += 10) {
      final rad = deg * math.pi / 180;
      final isMajor = deg % 30 == 0;
      final dir = Offset(math.sin(rad), -math.cos(rad));
      final outer = radius - 4;
      final inner = outer - (isMajor ? 10 : 5);
      canvas.drawLine(
        center + dir * outer,
        center + dir * inner,
        Paint()
          ..color = tickColor
          ..strokeWidth = isMajor ? 1.6 : 1,
      );

      // Degree labels lean along the ring like a printed compass card;
      // cardinal letters (drawn separately below) stay upright.
      if (isMajor && deg % 90 != 0) {
        _drawLabel(
          canvas,
          '$deg°',
          center,
          rad,
          radius - 22,
          labelColor,
          9,
          rotate: true,
        );
      }
    }

    for (var i = 0; i < 4; i++) {
      final rad = i * 90 * math.pi / 180;
      _drawLabel(
        canvas,
        _cardinals[i],
        center,
        rad,
        radius - 22,
        i == 0 ? _northColor : labelColor,
        13,
        bold: true,
      );
    }

    final dir = Offset(math.sin(qiblahAngleRad), -math.cos(qiblahAngleRad));
    final tip = center + dir * (radius * 0.62);
    final tail = center - dir * (radius * 0.22);
    canvas.drawLine(
      tail,
      tip,
      Paint()
        ..color = needleColor
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    const arrowBase = 8.0;
    final normal = Offset(-dir.dy, dir.dx);
    final arrowP2 = tip - dir * 12 + normal * arrowBase / 2;
    final arrowP3 = tip - dir * 12 - normal * arrowBase / 2;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(arrowP2.dx, arrowP2.dy)
        ..lineTo(arrowP3.dx, arrowP3.dy)
        ..close(),
      Paint()..color = needleColor,
    );
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset center,
    double rad,
    double distance,
    Color color,
    double fontSize, {
    bool bold = false,
    bool rotate = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pos = center + Offset(math.sin(rad), -math.cos(rad)) * distance;

    if (!rotate) {
      painter.paint(
        canvas,
        pos - Offset(painter.width / 2, painter.height / 2),
      );
      return;
    }

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    // Flip on the bottom half so the label reads upright rather than
    // upside-down while still leaning along the ring.
    final isBottomHalf = rad > math.pi / 2 && rad < math.pi * 1.5;
    canvas.rotate(isBottomHalf ? rad + math.pi : rad);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassFacePainter oldDelegate) {
    return oldDelegate.qiblahAngleRad != qiblahAngleRad ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.tickColor != tickColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.needleColor != needleColor;
  }
}
