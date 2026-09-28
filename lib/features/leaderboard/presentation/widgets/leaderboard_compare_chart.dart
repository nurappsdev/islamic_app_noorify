import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/localized_text.dart';

const leaderboardMyColor = Color(0xFF5D896D);
const leaderboardCompetitorColor = Color(0xFFA9B96A);

/// `30.5` -> `30.5`, `93.0` -> `93`, `62.876` -> `62.88`.
String formatLeaderboardPoints(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// The design's two overlapping peaks: "My Position" against the nearest
/// competitor above (the user's points plus `pointsBehindNext`). Both heights
/// come straight from the API; nothing else is drawn or invented, so a leader
/// (no one above) gets a single peak.
class LeaderboardCompareChart extends StatelessWidget {
  const LeaderboardCompareChart({
    super.key,
    required this.myPoints,
    this.competitorPoints,
  });

  final num myPoints;
  final num? competitorPoints;

  static const _steps = 4;

  /// A y-axis ceiling that divides into [_steps] tidy steps.
  static double niceMax(double value) {
    if (value <= 0) return 100;
    final magnitude = math.pow(10, (math.log(value) / math.ln10).floor());
    final norm = value / magnitude;
    final nice = [1, 2, 4, 5, 8, 10].firstWhere((n) => norm <= n);
    return nice * magnitude.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final top = math.max(myPoints, competitorPoints ?? 0).toDouble();
    final maxY = niceMax(top);
    final ticks = [
      for (var i = 0; i <= _steps; i++)
        context.localizedDigits(formatLeaderboardPoints(maxY * i / _steps)),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 230.h,
      child: CustomPaint(
        size: Size.infinite,
        painter: _ComparePainter(
          myPoints: myPoints.toDouble(),
          competitorPoints: competitorPoints?.toDouble(),
          myLabel: context.localizedDigits(formatLeaderboardPoints(myPoints)),
          competitorLabel: competitorPoints == null
              ? null
              : context.localizedDigits(
                  formatLeaderboardPoints(competitorPoints!),
                ),
          maxY: maxY,
          ticks: ticks,
          gridColor: isDark ? const Color(0xFF3A3F33) : const Color(0xFFECEFE1),
          axisTextColor: isDark
              ? const Color(0xFFB8C08F)
              : const Color(0xFF9AA279),
        ),
      ),
    );
  }
}

class _ComparePainter extends CustomPainter {
  _ComparePainter({
    required this.myPoints,
    required this.competitorPoints,
    required this.myLabel,
    required this.competitorLabel,
    required this.maxY,
    required this.ticks,
    required this.gridColor,
    required this.axisTextColor,
  });

  final double myPoints;
  final double? competitorPoints;
  final String myLabel;
  final String? competitorLabel;
  final double maxY;
  final List<String> ticks;
  final Color gridColor;
  final Color axisTextColor;

  // Where each peak sits across the plot, and where the competitor's starts.
  static const _myPeakAt = .33;
  static const _competitorStartAt = .28;
  static const _competitorPeakAt = .62;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 36.0;
    const topPad = 44.0;
    const bottomPad = 4.0;
    final left = leftPad;
    final right = size.width - 6;
    final top = topPad;
    final bottom = size.height - bottomPad;
    final width = right - left;
    final height = bottom - top;

    double yAt(double v) => bottom - height * (v / maxY).clamp(0.0, 1.0);

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < ticks.length; i++) {
      final y = bottom - height * i / (ticks.length - 1);
      canvas.drawLine(Offset(left, y), Offset(right, y), grid);
      _text(
        canvas,
        ticks[i],
        Offset(left - 8, y),
        color: axisTextColor,
        fontSize: 9,
        anchorRight: true,
        anchorMiddleY: true,
      );
    }

    final competitor = competitorPoints;
    Offset? competitorPeak;
    if (competitor != null) {
      competitorPeak = Offset(
        left + width * _competitorPeakAt,
        yAt(competitor),
      );
      _area(
        canvas,
        Offset(left + width * _competitorStartAt, bottom),
        competitorPeak,
        Offset(right, bottom),
        leaderboardCompetitorColor,
        top,
        bottom,
      );
    }
    final myPeak = Offset(left + width * _myPeakAt, yAt(myPoints));
    _area(
      canvas,
      Offset(left, bottom),
      myPeak,
      Offset(right, bottom),
      leaderboardMyColor,
      top,
      bottom,
    );

    if (competitorPeak != null && competitorLabel != null) {
      _bubble(
        canvas,
        size,
        competitorPeak,
        competitorLabel!,
        leaderboardCompetitorColor,
      );
    }
    _bubble(canvas, size, myPeak, myLabel, leaderboardMyColor);
  }

  void _area(
    Canvas canvas,
    Offset start,
    Offset peak,
    Offset end,
    Color color,
    double top,
    double bottom,
  ) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(peak.dx, peak.dy)
      ..lineTo(end.dx, end.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .55), color.withValues(alpha: .28)],
        ).createShader(Rect.fromLTRB(start.dx, top, end.dx, bottom)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// A pill (dot + [label]) resting just above [peak].
  void _bubble(
    Canvas canvas,
    Size size,
    Offset peak,
    String label,
    Color color,
  ) {
    final tp = _painter(label, const Color(0xFF3E4A2A), 10);
    const h = 22.0;
    final w = tp.width + 26;
    final rect = Rect.fromLTWH(
      (peak.dx - w / 2).clamp(0.0, math.max(0.0, size.width - w)),
      math.max(0.0, peak.dy - 8 - h),
      w,
      h,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(11)),
      Paint()..color = color.withValues(alpha: .6),
    );
    canvas.drawCircle(
      Offset(rect.left + 11, rect.center.dy),
      3,
      Paint()..color = const Color(0xFF3F4A32),
    );
    tp.paint(canvas, Offset(rect.left + 19, rect.center.dy - tp.height / 2));
  }

  TextPainter _painter(String text, Color color, double fontSize) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _text(
    Canvas canvas,
    String text,
    Offset offset, {
    required Color color,
    required double fontSize,
    bool anchorRight = false,
    bool anchorMiddleY = false,
  }) {
    final tp = _painter(text, color, fontSize);
    tp.paint(
      canvas,
      Offset(
        anchorRight ? offset.dx - tp.width : offset.dx,
        anchorMiddleY ? offset.dy - tp.height / 2 : offset.dy,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ComparePainter old) =>
      old.myPoints != myPoints ||
      old.competitorPoints != competitorPoints ||
      old.maxY != maxY ||
      old.myLabel != myLabel ||
      old.competitorLabel != competitorLabel ||
      old.gridColor != gridColor;
}
