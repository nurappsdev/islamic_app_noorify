import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Paints the soft, flower-scalloped square badge behind each name card
/// (design `img_27.png`): a rounded-square outline whose edge ripples in
/// small, evenly-spaced outward petals, like a certificate rosette.
///
/// Built by walking a rounded rectangle's perimeter at a constant arc-length
/// step and displacing each point outward along its local normal by
/// `amplitude * cos(bumps * 2π * s/perimeter)` — arc-length (not the raw
/// parametric angle a superellipse formula would use) keeps the petals the
/// same size all the way around, including through the corners.
class AsmaScallopBadge extends StatelessWidget {
  const AsmaScallopBadge({
    super.key,
    required this.fillColor,
    this.borderColor,
    this.secondaryFillColor,
  });

  final Color fillColor;
  final Color? borderColor;

  /// A second, slightly larger badge painted behind the main one (bumps
  /// phase-shifted) for the faint layered/petal-peeking-out look in the
  /// reference design.
  final Color? secondaryFillColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScallopBadgePainter(
        fillColor: fillColor,
        borderColor: borderColor,
        secondaryFillColor: secondaryFillColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ScallopBadgePainter extends CustomPainter {
  const _ScallopBadgePainter({
    required this.fillColor,
    this.borderColor,
    this.secondaryFillColor,
  });

  final Color fillColor;
  final Color? borderColor;
  final Color? secondaryFillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (secondaryFillColor != null) {
      final secondary = _scallopedRoundedRectPath(
        size,
        inset: -size.shortestSide * .015,
        bumps: 14,
        amplitude: size.shortestSide * .028,
        phase: math.pi / 7,
      );
      canvas.drawPath(secondary, Paint()..color = secondaryFillColor!);
    }

    final path = _scallopedRoundedRectPath(
      size,
      inset: size.shortestSide * .01,
      bumps: 14,
      amplitude: size.shortestSide * .022,
      phase: 0,
    );
    canvas.drawPath(path, Paint()..color = fillColor);
    if (borderColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  /// A rounded rect (corner radius ~28% of the short side) whose perimeter
  /// is displaced outward by a cosine ripple, sampled at constant arc-length
  /// steps so the petals stay evenly sized through straight edges and
  /// corners alike.
  Path _scallopedRoundedRectPath(
    Size size, {
    required double inset,
    required int bumps,
    required double amplitude,
    required double phase,
  }) {
    final w = size.width - inset * 2;
    final h = size.height - inset * 2;
    final left = inset, top = inset, right = size.width - inset;
    final bottom = size.height - inset;
    final r = math.min(w, h) * .28;
    final straightW = w - 2 * r;
    final straightH = h - 2 * r;
    final cornerLen = r * (math.pi / 2);
    final perimeter = 2 * straightW + 2 * straightH + 4 * cornerLen;

    final trCenter = Offset(right - r, top + r);
    final brCenter = Offset(right - r, bottom - r);
    final blCenter = Offset(left + r, bottom - r);
    final tlCenter = Offset(left + r, top + r);

    // Cumulative arc-length at the start of each of the 8 segments, in
    // clockwise order starting from the top edge.
    final segLens = [
      straightW,
      cornerLen,
      straightH,
      cornerLen,
      straightW,
      cornerLen,
      straightH,
      cornerLen,
    ];
    final segStarts = <double>[0];
    for (var i = 0; i < segLens.length - 1; i++) {
      segStarts.add(segStarts.last + segLens[i]);
    }

    (Offset, Offset) pointAndNormalAt(double s) {
      var segIndex = 7;
      for (var i = 0; i < 8; i++) {
        final end = segStarts[i] + segLens[i];
        if (s < end || i == 7) {
          segIndex = i;
          break;
        }
      }
      final local = s - segStarts[segIndex];
      switch (segIndex) {
        case 0: // top edge, left -> right
          return (Offset(left + r + local, top), const Offset(0, -1));
        case 1: // top-right corner
          final theta = -math.pi / 2 + (local / r);
          final n = Offset(math.cos(theta), math.sin(theta));
          return (trCenter + n * r, n);
        case 2: // right edge, top -> bottom
          return (Offset(right, top + r + local), const Offset(1, 0));
        case 3: // bottom-right corner
          final theta = 0 + (local / r);
          final n = Offset(math.cos(theta), math.sin(theta));
          return (brCenter + n * r, n);
        case 4: // bottom edge, right -> left
          return (Offset(right - r - local, bottom), const Offset(0, 1));
        case 5: // bottom-left corner
          final theta = math.pi / 2 + (local / r);
          final n = Offset(math.cos(theta), math.sin(theta));
          return (blCenter + n * r, n);
        case 6: // left edge, bottom -> top
          return (Offset(left, bottom - r - local), const Offset(-1, 0));
        default: // top-left corner
          final theta = math.pi + (local / r);
          final n = Offset(math.cos(theta), math.sin(theta));
          return (tlCenter + n * r, n);
      }
    }

    const steps = 320;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final s = (i / steps) * perimeter;
      final (base, normal) = pointAndNormalAt(s);
      final ripple =
          amplitude * math.cos(bumps * 2 * math.pi * (s / perimeter) + phase);
      final p = base + normal * ripple;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _ScallopBadgePainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.secondaryFillColor != secondaryFillColor;
}
