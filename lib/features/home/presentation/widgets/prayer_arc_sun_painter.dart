import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Renders the day-progress arc together with the sun (or, once Maghrib
/// starts, a moon) positioned along it, both driven by [progress] — the
/// fraction (0..1) elapsed across the current phase ([isNight] selects
/// whether that phase is daylight, sunrise..sunset, or night,
/// Maghrib..next Fajr).
class PrayerDayProgress extends StatelessWidget {
  const PrayerDayProgress({
    super.key,
    required this.progress,
    this.isNight = false,
  });

  final double progress;
  final bool isNight;

  static const _strokeWidth = 10.0;
  static const _sunDiameter = 43.0;
  static const _nightActiveColor = Color(0xFF6C7FB5);

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
                activeColor: isNight ? _nightActiveColor : null,
              ),
            ),
            Positioned(
              left: sunCenter.dx - sunDiameter / 2,
              top: sunCenter.dy - sunDiameter / 2,
              child: SizedBox.square(
                dimension: sunDiameter,
                child: CustomPaint(
                  painter: isNight
                      ? const PrayerMoonPainter()
                      : const PrayerSunPainter(),
                ),
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
  const PrayerArcPainter({
    required this.progress,
    required this.strokeWidth,
    this.activeColor,
  });

  /// Fraction (0..1) elapsed across the current phase (day or night).
  final double progress;
  final double strokeWidth;

  /// Overrides the default (daylight) active-arc color, e.g. for night.
  final Color? activeColor;

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
      ..color = activeColor ?? const Color(0xFF5D8067)
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
      oldDelegate.progress != progress || oldDelegate.activeColor != activeColor;
}

class PrayerSunPainter extends CustomPainter {
  const PrayerSunPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    // Soft glow behind the disc, for a warmer, less flat-looking sun.
    canvas.drawCircle(
      center,
      size.width * .42,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFD37A).withValues(alpha: .55),
            const Color(0xFFFFD37A).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * .42)),
    );

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

    // Disc with a subtle light-to-dark gradient instead of a flat fill.
    canvas.drawCircle(
      center,
      size.width * .23,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.topLeft,
          colors: const [Color(0xFFFFD37A), Color(0xFFFF9A1F)],
        ).createShader(
          Rect.fromCircle(center: center, radius: size.width * .23),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PrayerMoonPainter extends CustomPainter {
  const PrayerMoonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * .27;

    // Soft glow behind the crescent.
    canvas.drawCircle(
      center,
      size.width * .42,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFEDEBFB).withValues(alpha: .45),
            const Color(0xFFEDEBFB).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * .42)),
    );

    // A crescent is a filled disc with a second, offset disc cut out of it
    // (BlendMode.clear punches real transparency, so it reads correctly
    // over any background).
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDFBEF), Color(0xFFE3E0F5)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center.translate(size.width * .16, -size.height * .05),
      radius * .82,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    // A couple of small stars alongside the crescent.
    final starPaint = Paint()..color = const Color(0xFFF4F1E3).withValues(alpha: .85);
    canvas.drawCircle(
      Offset(center.dx - radius * .95, center.dy - radius * .7),
      size.width * .035,
      starPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 1.05, center.dy + radius * .5),
      size.width * .025,
      starPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
