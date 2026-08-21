import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

class AmolProgressRing extends StatelessWidget {
  const AmolProgressRing({
    super.key,
    required this.label,
    required this.progress,
    required this.dimension,
    required this.holeDimension,
    this.holeColor = const Color(0xFFDDE8AE),
    this.labelStyle,
  });

  final String label;
  final double progress;
  final double dimension;
  final double holeDimension;
  final Color holeColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: dimension,
      child: CustomPaint(
        painter: AmolProgressRingPainter(progress: progress),
        child: Center(
          child: Container(
            width: holeDimension,
            height: holeDimension,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: holeColor, shape: BoxShape.circle),
            child: Text(
              label,
              style:
                  labelStyle ??
                  homeSansStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class AmolProgressRingPainter extends CustomPainter {
  const AmolProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * .12;
    final ringRect =
        Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final clampedProgress = progress.clamp(0.0, 1.0);

    final trackPaint = Paint()
      ..color = const Color(0xFFF0EE74)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xFF879461)
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
    return oldDelegate.progress != progress;
  }
}
