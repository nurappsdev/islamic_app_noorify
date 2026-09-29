import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../quran_text.dart';

/// What a reading chart plots: minutes read per day (oldest first), the
/// user's and, optionally, the compared user's.
class QuranChartData {
  const QuranChartData({
    required this.labels,
    required this.mine,
    this.competitor,
    this.competitorBadge = '',
  });

  /// One label per day, under its point.
  final List<String> labels;
  final List<double> mine;

  /// Same length as [mine]; null when there is nobody to compare with.
  final List<double>? competitor;

  /// The compared user's initials, shown on their points.
  final String competitorBadge;

  /// A round top for the Y axis, just above the largest value.
  double get maxY => quranChartMax([...mine, ...?competitor]);
}

/// A round axis maximum (4 equal steps of 1, 2, 2.5 or 5 x 10^n) at or
/// above every value; 4 when all are zero.
double quranChartMax(Iterable<double> values) {
  final top = values.fold<double>(0, math.max);
  if (top <= 0) return 4;
  final raw = top / 4;
  final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor());
  final step = [
    1,
    2,
    2.5,
    5,
    10,
  ].map((m) => m * magnitude).firstWhere((candidate) => candidate >= raw);
  return step * 4.0;
}

/// The five gridline values from 0 to [maxY].
List<double> _levels(double maxY) => [
  for (var i = 0; i <= 4; i++) maxY * i / 4,
];

/// A gridline label: whole numbers plainly, others to one decimal.
String _axisLabel(double value, String Function(Object) number) => number(
  value == value.roundToDouble() ? value.toInt() : value.toStringAsFixed(1),
);

// ============================================================================
// 1. WEEKLY CHART
// ============================================================================

class QuranWeeklyChart extends StatelessWidget {
  const QuranWeeklyChart({
    super.key,
    required this.data,
    this.showCompetitor = true,
  });

  final QuranChartData data;
  final bool showCompetitor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _WeeklyChartPainter(
            data: data,
            number: QuranText.of(context).n,
            showCompetitor: showCompetitor && data.competitor != null,
          ),
        );
      },
    );
  }
}

class _WeeklyChartPainter extends CustomPainter {
  _WeeklyChartPainter({
    required this.data,
    required this.number,
    required this.showCompetitor,
  });

  final QuranChartData data;
  final String Function(Object) number;
  final bool showCompetitor;

  List<String> get labels => data.labels;
  List<double> get myValues => data.mine;
  List<double> get competitorValues => data.competitor ?? const [];

  static const _leftPad = 34.0;
  static const _rightPad = 8.0;
  static const _topPad = 34.0;
  static const _bottomPad = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    final chartLeft = _leftPad;
    final chartRight = size.width - _rightPad;
    final chartTop = _topPad;
    final chartBottom = size.height - _bottomPad;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final maxY = data.maxY;

    // 1. Horizontal dotted lines and Y labels
    for (final level in _levels(maxY)) {
      final y = chartBottom - chartHeight * (level / maxY);
      drawChartText(
        canvas,
        _axisLabel(level, number),
        Offset(chartLeft - 6, y),
        color: const Color(0xFF8E9582),
        fontSize: 10.5,
        align: TextAlign.right,
        anchorRight: true,
        anchorMiddleY: true,
      );
      drawChartDottedLine(
        canvas,
        Offset(chartLeft, y),
        Offset(chartRight, y),
        color: const Color(0xFFE2E7DA),
      );
    }

    final count = labels.length;
    if (count == 0 || myValues.length != count) return;
    double xAt(int i) => count == 1
        ? chartLeft + chartWidth / 2
        : chartLeft + chartWidth * (i / (count - 1));
    double yAt(double v) => chartBottom - chartHeight * (v / maxY);

    // 2. Day labels
    for (var i = 0; i < count; i++) {
      drawChartText(
        canvas,
        labels[i],
        Offset(xAt(i), chartBottom + 8),
        color: const Color(0xFF282442),
        fontSize: 12,
        anchorCenterX: true,
      );
    }

    final myPoints = [
      for (var i = 0; i < count; i++) Offset(xAt(i), yAt(myValues[i])),
    ];

    final withCompetitor = showCompetitor && competitorValues.length == count;

    // 3. Competitor Area
    if (withCompetitor) {
      final compPoints = [
        for (var i = 0; i < count; i++)
          Offset(xAt(i), yAt(competitorValues[i])),
      ];
      drawSplineArea(
        canvas: canvas,
        points: compPoints,
        lineColor: const Color(0xFF8F9F4A),
        gradientColors: [
          const Color(0xFFD6DBFF).withValues(alpha: 0.55),
          const Color(0xFFEBF0FF).withValues(alpha: 0.20),
          Colors.transparent,
        ],
        chartLeft: chartLeft,
        chartTop: chartTop,
        chartRight: chartRight,
        chartBottom: chartBottom,
      );
    }

    // 4. My Position Area
    drawSplineArea(
      canvas: canvas,
      points: myPoints,
      lineColor: const Color(0xFF5D7858),
      gradientColors: [
        const Color(0xFF8EC4E5).withValues(alpha: 0.40),
        const Color(0xFFC7E5F3).withValues(alpha: 0.16),
        Colors.transparent,
      ],
      chartLeft: chartLeft,
      chartTop: chartTop,
      chartRight: chartRight,
      chartBottom: chartBottom,
    );

    // 5. My Position node markers
    for (final p in myPoints) {
      canvas.drawCircle(
        p,
        7.5,
        Paint()..color = const Color(0xFF5D7858).withValues(alpha: 0.22),
      );
      canvas.drawCircle(p, 3.5, Paint()..color = const Color(0xFF5D7858));
    }

    // 6. Competitor badges
    if (withCompetitor) {
      final compPoints = [
        for (var i = 0; i < count; i++)
          Offset(xAt(i), yAt(competitorValues[i])),
      ];
      for (final point in compPoints) {
        drawCompetitorBadge(canvas, point, data.competitorBadge);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyChartPainter oldDelegate) =>
      oldDelegate.showCompetitor != showCompetitor ||
      oldDelegate.data != data ||
      oldDelegate.number('1') != number('1');
}

// ============================================================================
// 2. MONTHLY CHART
// ============================================================================

class QuranMonthlyChart extends StatelessWidget {
  const QuranMonthlyChart({
    super.key,
    required this.data,
    required this.controller,
    required this.scrollProgress,
    this.showCompetitor = true,
  });

  final QuranChartData data;
  final ScrollController controller;
  final double scrollProgress;
  final bool showCompetitor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const leftPad = 34.0;
        final viewportChartWidth = constraints.maxWidth - leftPad - 8.0;
        final dayStep = viewportChartWidth / 10.0;
        final totalScrollWidth = dayStep * math.max(data.labels.length - 1, 0);
        final t = QuranText.of(context);
        final maxY = data.maxY;

        return Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 40,
              width: constraints.maxWidth,
              child: CustomPaint(
                painter: _YAxisGridPainter(
                  leftPad: leftPad,
                  number: t.n,
                  maxY: maxY,
                ),
              ),
            ),
            Positioned(
              left: leftPad,
              top: 0,
              right: 8,
              bottom: 24,
              child: SingleChildScrollView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: totalScrollWidth + 30,
                  height: constraints.maxHeight - 24,
                  child: CustomPaint(
                    painter: _MonthlyScrollablePainter(
                      data: data,
                      maxY: maxY,
                      dayStep: dayStep,
                      showCompetitor:
                          showCompetitor &&
                          data.competitor?.length == data.labels.length,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: leftPad + 4,
              right: 12,
              bottom: 4,
              child: QuranScrollIndicatorBar(progress: scrollProgress),
            ),
          ],
        );
      },
    );
  }
}

class _YAxisGridPainter extends CustomPainter {
  _YAxisGridPainter({
    required this.leftPad,
    required this.number,
    required this.maxY,
  });

  final String Function(Object) number;
  final double maxY;

  final double leftPad;

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 34.0;
    const bottomPad = 26.0;
    final chartBottom = size.height - bottomPad;
    final chartTop = topPad;
    final chartHeight = chartBottom - chartTop;

    for (final level in _levels(maxY)) {
      final y = chartBottom - chartHeight * (level / maxY);
      drawChartText(
        canvas,
        _axisLabel(level, number),
        Offset(leftPad - 6, y),
        color: const Color(0xFF8E9582),
        fontSize: 10.5,
        align: TextAlign.right,
        anchorRight: true,
        anchorMiddleY: true,
      );
      drawChartDottedLine(
        canvas,
        Offset(leftPad, y),
        Offset(size.width - 8, y),
        color: const Color(0xFFE2E7DA),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _YAxisGridPainter oldDelegate) =>
      oldDelegate.maxY != maxY || oldDelegate.number('1') != number('1');
}

class _MonthlyScrollablePainter extends CustomPainter {
  _MonthlyScrollablePainter({
    required this.data,
    required this.maxY,
    required this.dayStep,
    required this.showCompetitor,
  });

  final QuranChartData data;
  final double maxY;
  final double dayStep;
  final bool showCompetitor;

  List<String> get days => data.labels;
  List<double> get myValues => data.mine;
  List<double> get competitorValues => data.competitor ?? const [];

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 34.0;
    const bottomPad = 26.0;
    final chartTop = topPad;
    final chartBottom = size.height - bottomPad;
    final chartHeight = chartBottom - chartTop;

    double xAt(int i) => i * dayStep + 10.0;
    double yAt(double v) => chartBottom - chartHeight * (v / maxY);

    final count = days.length;
    if (count == 0 || myValues.length != count) return;

    // Day numbers
    for (var i = 0; i < count; i++) {
      drawChartText(
        canvas,
        days[i],
        Offset(xAt(i), chartBottom + 8),
        color: const Color(0xFF282442),
        fontSize: 12,
        anchorCenterX: true,
      );
    }

    final myPoints = [
      for (var i = 0; i < count; i++) Offset(xAt(i), yAt(myValues[i])),
    ];

    // Competitor area
    if (showCompetitor) {
      final compPoints = [
        for (var i = 0; i < count; i++)
          Offset(xAt(i), yAt(competitorValues[i])),
      ];
      drawSplineArea(
        canvas: canvas,
        points: compPoints,
        lineColor: const Color(0xFF8F9F4A),
        gradientColors: [
          const Color(0xFFD6DBFF).withValues(alpha: 0.55),
          const Color(0xFFEBF0FF).withValues(alpha: 0.20),
          Colors.transparent,
        ],
        chartLeft: 0,
        chartTop: chartTop,
        chartRight: size.width,
        chartBottom: chartBottom,
      );
    }

    // My Position area
    drawSplineArea(
      canvas: canvas,
      points: myPoints,
      lineColor: const Color(0xFF5D7858),
      gradientColors: [
        const Color(0xFF8EC4E5).withValues(alpha: 0.40),
        const Color(0xFFC7E5F3).withValues(alpha: 0.16),
        Colors.transparent,
      ],
      chartLeft: 0,
      chartTop: chartTop,
      chartRight: size.width,
      chartBottom: chartBottom,
    );

    // My Position markers
    for (final p in myPoints) {
      canvas.drawCircle(
        p,
        7.5,
        Paint()..color = const Color(0xFF5D7858).withValues(alpha: 0.22),
      );
      canvas.drawCircle(p, 3.5, Paint()..color = const Color(0xFF5D7858));
    }

    // Competitor badges
    if (showCompetitor) {
      final compPoints = [
        for (var i = 0; i < count; i++)
          Offset(xAt(i), yAt(competitorValues[i])),
      ];
      for (final point in compPoints) {
        drawCompetitorBadge(canvas, point, data.competitorBadge);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyScrollablePainter oldDelegate) =>
      oldDelegate.showCompetitor != showCompetitor ||
      oldDelegate.data != data ||
      oldDelegate.maxY != maxY;
}

class QuranScrollIndicatorBar extends StatelessWidget {
  const QuranScrollIndicatorBar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0D2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalW = constraints.maxWidth;
          final thumbW = totalW * 0.38;
          final maxLeft = totalW - thumbW;
          final left = maxLeft * progress;

          return Stack(
            children: [
              Positioned(
                left: left,
                width: thumbW,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0E09B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// 3. DAILY CHART
// ============================================================================

class QuranDailyChart extends StatelessWidget {
  const QuranDailyChart({
    super.key,
    required this.mine,
    this.competitor,
    this.competitorBadge = '',
    this.showCompetitor = true,
  });

  /// Minutes read today, by the user and by the compared user.
  final double mine;
  final double? competitor;
  final String competitorBadge;
  final bool showCompetitor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _DailyChartPainter(
            mine: mine,
            competitor: showCompetitor ? competitor : null,
            competitorBadge: competitorBadge,
            number: QuranText.of(context).n,
            caption: QuranText.of(context).todaysValue,
          ),
        );
      },
    );
  }
}

class _DailyChartPainter extends CustomPainter {
  const _DailyChartPainter({
    required this.mine,
    required this.competitor,
    required this.competitorBadge,
    required this.number,
    required this.caption,
  });

  final double mine;
  final double? competitor;
  final String competitorBadge;
  final String Function(Object) number;
  final String caption;

  static const _leftPad = 34.0;
  static const _rightPad = 8.0;
  static const _topPad = 34.0;
  static const _bottomPad = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final chartLeft = _leftPad;
    final chartRight = size.width - _rightPad;
    final chartTop = _topPad;
    final chartBottom = size.height - _bottomPad;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final maxY = quranChartMax([mine, ?competitor]);

    // Grid lines and Y labels
    for (final level in _levels(maxY)) {
      final y = chartBottom - chartHeight * (level / maxY);
      drawChartText(
        canvas,
        _axisLabel(level, number),
        Offset(chartLeft - 6, y),
        color: const Color(0xFF8E9582),
        fontSize: 10.5,
        align: TextAlign.right,
        anchorRight: true,
        anchorMiddleY: true,
      );
      drawChartDottedLine(
        canvas,
        Offset(chartLeft, y),
        Offset(chartRight, y),
        color: const Color(0xFFE2E7DA),
      );
    }

    // Centered label
    drawChartText(
      canvas,
      caption,
      Offset(chartLeft + chartWidth / 2, chartBottom + 8),
      color: const Color(0xFF282442),
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      anchorCenterX: true,
    );

    // 1. Competitor Mountain (behind)
    final theirs = competitor;
    if (theirs != null && theirs > 0) {
      final compApexX = chartLeft + chartWidth * 0.70;
      final compApexY = chartBottom - chartHeight * (theirs / maxY);
      final compStartX = chartLeft + chartWidth * 0.50;
      final compEndX = chartLeft + chartWidth * 0.94;

      final compPath = Path()
        ..moveTo(compStartX, chartBottom)
        ..lineTo(compApexX, compApexY)
        ..lineTo(compEndX, chartBottom)
        ..close();

      canvas.drawPath(
        compPath,
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF8F9F4A).withValues(alpha: 0.28),
                  const Color(0xFF8F9F4A).withValues(alpha: 0.12),
                ],
              ).createShader(
                Rect.fromLTRB(compStartX, compApexY, compEndX, chartBottom),
              ),
      );

      canvas.drawPath(
        Path()
          ..moveTo(compStartX, chartBottom)
          ..lineTo(compApexX, compApexY)
          ..lineTo(compEndX, chartBottom),
        Paint()
          ..color = const Color(0xFF8F9F4A).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );

      drawCompetitorBadge(
        canvas,
        Offset(compApexX, compApexY),
        competitorBadge,
      );
    }

    // 2. My Position Mountain (front)
    if (mine <= 0) return;
    final myApexX = chartLeft + chartWidth * 0.44;
    final myApexY = chartBottom - chartHeight * (mine / maxY);
    final myStartX = chartLeft;
    final myEndX = chartLeft + chartWidth * 0.94;

    final myPath = Path()
      ..moveTo(myStartX, chartBottom)
      ..lineTo(myApexX, myApexY)
      ..lineTo(myEndX, chartBottom)
      ..close();

    canvas.drawPath(
      myPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF5D7858).withValues(alpha: 0.42),
            const Color(0xFF5D7858).withValues(alpha: 0.22),
          ],
        ).createShader(Rect.fromLTRB(myStartX, myApexY, myEndX, chartBottom)),
    );

    canvas.drawPath(
      Path()
        ..moveTo(myStartX, chartBottom)
        ..lineTo(myApexX, myApexY)
        ..lineTo(myEndX, chartBottom),
      Paint()
        ..color = const Color(0xFF5D7858).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant _DailyChartPainter oldDelegate) =>
      oldDelegate.mine != mine ||
      oldDelegate.competitor != competitor ||
      oldDelegate.caption != caption;
}

// ============================================================================
// HELPER DRAWING UTILITIES
// ============================================================================

void drawSplineArea({
  required Canvas canvas,
  required List<Offset> points,
  required Color lineColor,
  required List<Color> gradientColors,
  required double chartLeft,
  required double chartTop,
  required double chartRight,
  required double chartBottom,
}) {
  if (points.isEmpty) return;
  if (points.length < 3) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final areaPath = Path.from(path)
      ..lineTo(points.last.dx, chartBottom)
      ..lineTo(points.first.dx, chartBottom)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ).createShader(
              Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom),
            ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    return;
  }

  final linePath = Path()..moveTo(points.first.dx, points.first.dy);
  double clampY(double y) => y.clamp(chartTop - 10, chartBottom).toDouble();

  for (var i = 0; i < points.length - 1; i++) {
    final p0 = points[math.max(i - 1, 0)];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = points[math.min(i + 2, points.length - 1)];

    linePath.cubicTo(
      p1.dx + (p2.dx - p0.dx) / 6,
      clampY(p1.dy + (p2.dy - p0.dy) / 6),
      p2.dx - (p3.dx - p1.dx) / 6,
      clampY(p2.dy - (p3.dy - p1.dy) / 6),
      p2.dx,
      p2.dy,
    );
  }

  final areaPath = Path.from(linePath)
    ..lineTo(points.last.dx, chartBottom)
    ..lineTo(points.first.dx, chartBottom)
    ..close();

  canvas.drawPath(
    areaPath,
    Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ).createShader(
            Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom),
          ),
  );

  canvas.drawPath(
    linePath,
    Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6,
  );
}

void drawCompetitorBadge(Canvas canvas, Offset anchor, String label) {
  if (label.isEmpty) return;
  const w = 38.0;
  const h = 22.0;
  final left = anchor.dx - w / 2;
  final top = anchor.dy - h - 3;

  final rrect = RRect.fromRectAndRadius(
    Rect.fromLTWH(left, top, w, h),
    const Radius.circular(9),
  );

  canvas.drawRRect(rrect, Paint()..color = const Color(0xFFD8E6A2));

  canvas.drawCircle(
    Offset(left + 10, top + h / 2),
    2.5,
    Paint()..color = const Color(0xFF6E7E38),
  );

  drawChartText(
    canvas,
    label,
    Offset(left + 23, top + h / 2),
    color: const Color(0xFF2C331B),
    fontSize: 11,
    fontWeight: FontWeight.w600,
    anchorCenterX: true,
    anchorMiddleY: true,
  );
}

void drawChartDottedLine(
  Canvas canvas,
  Offset start,
  Offset end, {
  required Color color,
}) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = 1.0;
  const dashWidth = 2.0;
  const dashGap = 3.0;

  var currentX = start.dx;
  final y = start.dy;
  while (currentX < end.dx) {
    final nextX = math.min(currentX + dashWidth, end.dx);
    canvas.drawLine(Offset(currentX, y), Offset(nextX, y), paint);
    currentX += dashWidth + dashGap;
  }
}

void drawChartText(
  Canvas canvas,
  String text,
  Offset pos, {
  required Color color,
  required double fontSize,
  FontWeight fontWeight = FontWeight.w400,
  TextAlign align = TextAlign.left,
  bool anchorRight = false,
  bool anchorCenterX = false,
  bool anchorMiddleY = false,
}) {
  final span = TextSpan(
    text: text,
    style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
  );
  final tp = TextPainter(
    text: span,
    textAlign: align,
    textDirection: TextDirection.ltr,
  )..layout();

  var x = pos.dx;
  if (anchorRight) {
    x -= tp.width;
  } else if (anchorCenterX) {
    x -= tp.width / 2;
  }

  var y = pos.dy;
  if (anchorMiddleY) {
    y -= tp.height / 2;
  }

  tp.paint(canvas, Offset(x, y));
}
