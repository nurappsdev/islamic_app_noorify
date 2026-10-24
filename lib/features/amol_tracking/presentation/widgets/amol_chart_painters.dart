import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';
import 'package:tuhfatul_muslim/core/theme/app_typography.dart';

class AmolLineChartPainter extends CustomPainter {
  const AmolLineChartPainter({
    required this.plotRect,
    required this.categories,
    required this.points,
    required this.competitorPoints,
    required this.maxY,
    required this.language,
    this.selectedIndex,
  });

  final Rect plotRect;
  final List<String> categories;
  final List<Offset> points;

  /// Same order as [points]; a `null` entry breaks the dashed line for
  /// that segment instead of interpolating across a pillar the server has
  /// no competitor score for.
  final List<Offset?> competitorPoints;
  final double maxY;
  final AppLanguage language;

  /// The category whose tooltip is open: its column gets a guide line and
  /// its points are drawn enlarged with a halo. Null when none is open.
  final int? selectedIndex;

  static const lineColor = Color(0xFF5D8067);
  // Matches _CompetitorBubble.dotColor / the legend's competitor dot, so
  // "my" vs "competitor" reads as the same color pairing everywhere on
  // the chart.
  static const competitorLineColor = Color(0xFFB9C776);
  static const _areaFillColor = Color(0xFF7C93D6);
  static const _gridColor = Color(0xFFE7E9DD);
  static const _labelColor = Color(0xFF8C9484);
  static const _ySteps = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _gridColor
      ..strokeWidth = 1;

    for (var i = 0; i <= _ySteps; i++) {
      final y = plotRect.bottom - plotRect.height * i / _ySteps;
      canvas.drawLine(
        Offset(plotRect.left, y),
        Offset(plotRect.right, y),
        gridPaint,
      );
      _paintLabel(
        canvas,
        localizeDigits((maxY * i / _ySteps).round().toString(), language),
        Offset(plotRect.left - 6.w, y),
        alignRight: true,
      );
    }

    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, plotRect.bottom)
        ..lineTo(points.first.dx, plotRect.bottom)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _areaFillColor.withValues(alpha: .45),
              _areaFillColor.withValues(alpha: .06),
            ],
          ).createShader(plotRect),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.r
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final selected = selectedIndex;
    if (selected != null && selected >= 0 && selected < points.length) {
      final x = points[selected].dx;
      final guide = Paint()
        ..color = lineColor.withValues(alpha: .45)
        ..strokeWidth = 1.2;
      for (var y = plotRect.top; y < plotRect.bottom; y += 6) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, (y + 3).clamp(plotRect.top, plotRect.bottom)),
          guide,
        );
      }
    }

    for (final point in points) {
      canvas.drawCircle(point, 5.r, Paint()..color = Colors.white);
      canvas.drawCircle(
        point,
        5.r,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.r,
      );
      canvas.drawCircle(point, 2.2.r, Paint()..color = lineColor);
    }

    // Competitor line: dashed, in the legend's competitor color, so "my"
    // (solid green) and "competitor" (dashed olive) are unmistakable at a
    // glance. Drawn as separate contiguous segments so a pillar the server
    // has no competitor score for breaks the line instead of interpolating
    // across it.
    final competitorPaint = Paint()
      ..color = competitorLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.r
      ..strokeCap = StrokeCap.round;
    var segment = <Offset>[];
    void flushSegment() {
      if (segment.length > 1) {
        _drawDashedPolyline(canvas, segment, competitorPaint);
      }
      segment = [];
    }

    for (final point in competitorPoints) {
      if (point == null) {
        flushSegment();
      } else {
        segment.add(point);
      }
    }
    flushSegment();

    for (final point in competitorPoints) {
      if (point == null) continue;
      canvas.drawCircle(point, 3.r, Paint()..color = competitorLineColor);
    }

    // Highlight the selected column's points on top of everything.
    if (selected != null && selected >= 0 && selected < points.length) {
      void highlight(Offset point, Color color) {
        canvas.drawCircle(
          point,
          11.r,
          Paint()..color = color.withValues(alpha: .22),
        );
        canvas.drawCircle(point, 6.5.r, Paint()..color = Colors.white);
        canvas.drawCircle(point, 4.5.r, Paint()..color = color);
      }

      if (selected < competitorPoints.length &&
          competitorPoints[selected] != null) {
        highlight(competitorPoints[selected]!, competitorLineColor);
      }
      highlight(points[selected], lineColor);
    }

    for (var i = 0; i < categories.length; i++) {
      final x = i < points.length ? points[i].dx : plotRect.left;
      canvas.save();
      canvas.translate(x, plotRect.bottom + 10.h);
      canvas.rotate(-0.6);
      _paintLabel(canvas, categories[i], Offset.zero, alignRight: true);
      canvas.restore();
    }
  }

  static void _paintLabel(
    Canvas canvas,
    String text,
    Offset anchor, {
    bool alignRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 9.sp,
          color: _labelColor,
          fontFamilyFallback: appFontFamilyFallback,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = alignRight
        ? Offset(anchor.dx - painter.width, anchor.dy - painter.height / 2)
        : anchor;
    painter.paint(canvas, offset);
  }

  /// Draws [points] as a dashed polyline (no dashing support in
  /// `dart:ui`/Canvas directly, so short solid segments are stepped along
  /// each leg by hand).
  static void _drawDashedPolyline(
    Canvas canvas,
    List<Offset> points,
    Paint paint,
  ) {
    const dashLength = 5.0;
    const gapLength = 4.0;
    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final legLength = (end - start).distance;
      if (legLength == 0) continue;
      final direction = (end - start) / legLength;
      var travelled = 0.0;
      while (travelled < legLength) {
        final dashEnd = (travelled + dashLength).clamp(0.0, legLength);
        canvas.drawLine(
          start + direction * travelled,
          start + direction * dashEnd,
          paint,
        );
        travelled += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant AmolLineChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.competitorPoints != competitorPoints ||
      oldDelegate.plotRect != plotRect ||
      oldDelegate.language != language ||
      oldDelegate.selectedIndex != selectedIndex;
}

/// Weekly tab's chart style (img reference: Hadith dashboard's weekly bar
/// chart): the same per-pillar `points`/`competitorPoints`
/// [AmolLineChartPainter] uses, drawn as overlapping columns — taller bar
/// behind, shorter in front — instead of a connected line. Grid, y-axis
/// labels and x-axis category labels are identical to
/// [AmolLineChartPainter]'s.
class AmolBarChartPainter extends CustomPainter {
  const AmolBarChartPainter({
    required this.plotRect,
    required this.categories,
    required this.points,
    required this.competitorPoints,
    required this.tickValues,
    required this.language,
    this.selectedIndex,
    this.verticalLabels = false,
  });

  final Rect plotRect;
  final List<String> categories;
  final List<Offset> points;
  final List<Offset?> competitorPoints;

  /// This window's own data-driven y-axis labels, evenly spaced from `0`
  /// to the axis ceiling (e.g. `[0, 50, 100, 150, 200, 250, 300]`) — see
  /// `niceAmolAxisTicks`. [points]/[competitorPoints] are already scaled
  /// against the same ceiling (`tickValues.last`), so this list only
  /// needs drawing, not any further ratio math.
  final List<double> tickValues;
  final AppLanguage language;
  final int? selectedIndex;

  /// Monthly's category labels read bottom-to-top instead of leaning
  /// diagonally (reference image).
  final bool verticalLabels;

  /// Every column's bar half-width — all columns (Fardh Prayer, Nafl
  /// Salat, Quran, etc.) are drawn at this same width; only their height
  /// differs, based on actual progress. Derived from the slotted spacing
  /// bar charts use (each category gets an equal `plotWidth / count`
  /// slot), so the bar — and the score bubble positioned at its top-left
  /// corner — always matches the slot it's actually centered in.
  static double barHalfWidth(int count, double plotWidth) {
    if (count <= 0) return 0.0;
    final stepX = plotWidth / count;
    return (stepX * 0.28).clamp(4.0, 16.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AmolLineChartPainter._gridColor
      ..strokeWidth = 1;

    // tickValues are evenly spaced by construction (0, step, 2*step, ...),
    // so each one's screen y is just its position in the list over the
    // list's own span — no separate ratio against a ceiling value needed.
    final lastTickIndex = tickValues.length - 1;
    for (var i = 0; i <= lastTickIndex; i++) {
      final y = lastTickIndex == 0
          ? plotRect.bottom
          : plotRect.bottom - plotRect.height * i / lastTickIndex;
      canvas.drawLine(
        Offset(plotRect.left, y),
        Offset(plotRect.right, y),
        gridPaint,
      );
      AmolLineChartPainter._paintLabel(
        canvas,
        localizeDigits(tickValues[i].round().toString(), language),
        Offset(plotRect.left - 6.w, y),
        alignRight: true,
      );
    }

    final halfWidth = barHalfWidth(points.length, plotRect.width);
    for (var i = 0; i < points.length; i++) {
      final competitor = i < competitorPoints.length
          ? competitorPoints[i]
          : null;
      final bars = <(Offset, Color)>[
        (points[i], AmolLineChartPainter.lineColor),
        if (competitor != null)
          (competitor, AmolLineChartPainter.competitorLineColor),
      ]..sort((a, b) => a.$1.dy.compareTo(b.$1.dy));
      for (final (point, color) in bars) {
        final left = (point.dx - halfWidth).clamp(
          plotRect.left,
          plotRect.right,
        );
        final right = (point.dx + halfWidth).clamp(
          plotRect.left,
          plotRect.right,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTRB(left, point.dy, right, plotRect.bottom),
            topLeft: Radius.circular(4.r),
            topRight: Radius.circular(4.r),
          ),
          Paint()..color = color,
        );
      }
    }

    // Highlight the selected column, same treatment as the line chart's.
    final selected = selectedIndex;
    if (selected != null && selected >= 0 && selected < points.length) {
      final x = points[selected].dx;
      final guide = Paint()
        ..color = AmolLineChartPainter.lineColor.withValues(alpha: .45)
        ..strokeWidth = 1.2;
      for (var y = plotRect.top; y < plotRect.bottom; y += 6) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, (y + 3).clamp(plotRect.top, plotRect.bottom)),
          guide,
        );
      }

      void highlight(Offset point, Color color) {
        canvas.drawCircle(
          point,
          11.r,
          Paint()..color = color.withValues(alpha: .22),
        );
        canvas.drawCircle(point, 6.5.r, Paint()..color = Colors.white);
        canvas.drawCircle(point, 4.5.r, Paint()..color = color);
      }

      if (selected < competitorPoints.length &&
          competitorPoints[selected] != null) {
        highlight(
          competitorPoints[selected]!,
          AmolLineChartPainter.competitorLineColor,
        );
      }
      highlight(points[selected], AmolLineChartPainter.lineColor);
    }

    for (var i = 0; i < categories.length; i++) {
      final x = i < points.length ? points[i].dx : plotRect.left;
      canvas.save();
      canvas.translate(x, plotRect.bottom + 10.h);
      canvas.rotate(verticalLabels ? -math.pi / 2 : -0.6);
      AmolLineChartPainter._paintLabel(
        canvas,
        categories[i],
        Offset.zero,
        alignRight: true,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant AmolBarChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.competitorPoints != competitorPoints ||
      oldDelegate.tickValues != tickValues ||
      oldDelegate.verticalLabels != verticalLabels ||
      oldDelegate.plotRect != plotRect ||
      oldDelegate.language != language ||
      oldDelegate.selectedIndex != selectedIndex;
}
