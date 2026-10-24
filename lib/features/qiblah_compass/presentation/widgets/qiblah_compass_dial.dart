import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/theme/app_palette.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/theme/app_typography.dart';

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
    this.labelFontScale = 1,
    this.cardinalFontWeight = FontWeight.w700,
  });

  final double qiblahAngle;
  final double heading;
  final double size;

  /// Scales the degree-number and N/E/S/W font sizes without touching the
  /// dial's geometry. The full-screen Qiblah compass uses the default
  /// (1.0); the smaller Home card dial passes a reduced scale so its labels
  /// don't look cluttered at that size.
  final double labelFontScale;

  /// Weight of the N/E/S/W letters. Defaults to the original bold weight;
  /// the Home card dial passes a lighter one to match its reduced scale.
  final FontWeight cardinalFontWeight;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final headingRad = heading * math.pi / 180;
    final qiblahRad = qiblahAngle * math.pi / 180;
    final markerRadius = size / 2 * 0.76;
    // The asset's own halo/rings render larger than the dial's footprint
    // (devImg/img_1.png); `Clip.none` below lets that extent paint without
    // being hard-cropped back down to `size`, and the tick/label painter
    // shares this same larger canvas so its two outer rings line up with
    // the asset's rings exactly.
    final faceSize = size * 1.34;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Layered glassy disc (halo + embossed rings baked into the
          // asset), matching the reference dial in img_1.png.
          Image.asset(
            'assets/compassIcon.png',
            width: faceSize,
            height: faceSize,
            fit: BoxFit.contain,
          ),
          Transform.rotate(
            angle: -headingRad,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size.square(faceSize),
                  painter: _CompassFacePainter(
                    qiblahAngleRad: qiblahRad,
                    tickColor: palette.textPrimary.withValues(alpha: 0.4),
                    labelColor: palette.textPrimary.withValues(alpha: 0.65),
                    needleColor: AppColor.primary,
                    labelFontScale: labelFontScale,
                    cardinalFontWeight: cardinalFontWeight,
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
    required this.tickColor,
    required this.labelColor,
    required this.needleColor,
    required this.labelFontScale,
    required this.cardinalFontWeight,
  });

  final double qiblahAngleRad;
  final Color tickColor;
  final Color labelColor;
  final Color needleColor;
  final double labelFontScale;
  final FontWeight cardinalFontWeight;

  static const _cardinals = ['N', 'E', 'S', 'W'];
  static const _northColor = Color(0xFFD1523B);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // `radius` spans the full asset (its outer circle, middle ring and
    // innermost disc, per the measured ring boundaries in
    // assets/compassIcon.png). The middle ring carries every degree number
    // (including 0°/90°/180°/270°, under the cardinals) plus the tick
    // marks; the outermost circle shows only the N/E/S/W labels, aligned
    // with those same angles (img_1.png). The innermost disc stays bare.
    final radius = size.width / 2;
    final midRingEdge = radius * 0.588;
    final outerEdge = radius * 0.90;

    for (var deg = 0; deg < 360; deg += 10) {
      final rad = deg * math.pi / 180;
      final isMajor = deg % 30 == 0;
      final dir = Offset(math.sin(rad), -math.cos(rad));
      final outer = midRingEdge - 4;
      final inner = outer - (isMajor ? 10 : 5);
      canvas.drawLine(
        center + dir * outer,
        center + dir * inner,
        Paint()
          ..color = tickColor
          ..strokeWidth = isMajor ? 1.6 : 1,
      );

      // Degree labels lean along the middle ring like a printed compass
      // card, including under the cardinal angles; the N/E/S/W letters
      // (drawn separately below) stay upright and sit on the outermost
      // circle instead.
      if (isMajor) {
        _drawLabel(
          canvas,
          '$deg°',
          center,
          rad,
          midRingEdge - 18,
          labelColor,
          9 * labelFontScale,
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
        outerEdge - 18,
        i == 0 ? _northColor : labelColor,
        13 * labelFontScale,
        fontWeight: cardinalFontWeight,
      );
    }

    // The needle's reach is independent of the marking bands above (it
    // points from the center disc out toward the Kaaba badge, which sits
    // at `markerRadius` in the parent widget), so it keeps the same
    // proportions the dial used before the asset grew to `faceSize`.
    final legacyRadius = radius * 0.746;
    final dir = Offset(math.sin(qiblahAngleRad), -math.cos(qiblahAngleRad));
    final tip = center + dir * (legacyRadius * 0.62);
    final tail = center - dir * (legacyRadius * 0.22);
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
    FontWeight fontWeight = FontWeight.w500,
    bool rotate = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamilyFallback: appFontFamilyFallback,
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
        oldDelegate.tickColor != tickColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.needleColor != needleColor ||
        oldDelegate.labelFontScale != labelFontScale ||
        oldDelegate.cardinalFontWeight != cardinalFontWeight;
  }
}
