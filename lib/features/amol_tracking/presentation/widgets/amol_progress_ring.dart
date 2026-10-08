import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/features/home/presentation/screens/home_screen.dart';

/// The two colours shared by an Amol card's progress ring, name badge, and
/// leading-logo tile. Keeping them here prevents those visual states from
/// drifting apart as the card is reused in different screens.
const amolProgressTrackColor = Color(0xFFFEFCD6);
const amolProgressFillColor = Color(0xFF879461);
const amolNameBadgeBorderColor = Color(0xFFA1AD59);

class AmolProgressRing extends StatelessWidget {
  const AmolProgressRing({
    super.key,
    required this.label,
    required this.progress,
    required this.dimension,
    required this.holeDimension,
    this.holeColor = const Color(0xFFDDE8AE),
    this.trackColor = amolProgressTrackColor,
    this.progressColor = amolProgressFillColor,
    this.labelStyle,
    this.strokeFactor = .12,
  });

  /// Ring thickness as a fraction of [dimension].
  final double strokeFactor;

  final String label;
  final double progress;
  final double dimension;
  final double holeDimension;
  final Color holeColor;
  final Color trackColor;
  final Color progressColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: dimension,
      child: CustomPaint(
        painter: AmolProgressRingPainter(
          progress: progress,
          strokeFactor: strokeFactor,
          trackColor: trackColor,
          progressColor: progressColor,
        ),
        child: Center(
          child: Container(
            width: holeDimension,
            height: holeDimension,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.surfaceColor(holeColor),
              shape: BoxShape.circle,
            ),
            // Scales a long value (e.g. "100.4 %") down instead of overflowing.
            child: Padding(
              padding: EdgeInsets.all(holeDimension * .06),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style:
                      labelStyle ??
                      homeSansStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AmolProgressRingPainter extends CustomPainter {
  const AmolProgressRingPainter({
    required this.progress,
    this.strokeFactor = .12,
    this.trackColor = amolProgressTrackColor,
    this.progressColor = amolProgressFillColor,
  });

  final double progress;
  final double strokeFactor;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * strokeFactor;
    final ringRect =
        Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final clampedProgress = progress.clamp(0.0, 1.0);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(ringRect, 0, math.pi * 2, false, trackPaint);
    canvas.drawArc(
      ringRect,
      -math.pi / 2,
      math.pi * 2 * clampedProgress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant AmolProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeFactor != strokeFactor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
