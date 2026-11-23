import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/theme/app_typography.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';

import '../../quran_text.dart';

/// What a reading chart plots: minutes read per day (oldest first), the
/// user's and, optionally, the compared user's.
class QuranChartData {
  const QuranChartData({
    required this.labels,
    required this.mine,
    this.competitor,
    this.competitorBadge = '',
    this.myPoints = const [],
    this.competitorPoints = const [],
    this.mySeconds = const [],
    this.competitorSeconds = const [],
    this.myName = '',
    this.competitorName = '',
  });

  /// One label per day, under its point.
  final List<String> labels;
  final List<double> mine;

  /// Same length as [mine]; null when there is nobody to compare with.
  final List<double>? competitor;

  /// The compared user's initials, shown on their points.
  final String competitorBadge;

  /// The points earned each day, in step with [mine] / [competitor]. Only the
  /// card a tapped point opens reads these; the chart itself plots minutes.
  /// Empty when the server sent none.
  final List<double> myPoints;
  final List<double> competitorPoints;

  /// The seconds read each day, so the card can give an exact time
  /// (`1 hr 5 min`) rather than rounded minutes. Empty when unknown.
  final List<int> mySeconds;
  final List<int> competitorSeconds;

  /// Who the two series belong to, for the card's rows.
  final String myName;
  final String competitorName;

  /// A round top for the Y axis, just above the largest value.
  double get maxY => quranChartMax([...mine, ...?competitor]);

  /// This day's reading for one series, as the card shows it: `null` where
  /// the server sent nothing for that day.
  ({double minutes, int? seconds, double? points}) at(
    int index, {
    required bool rival,
  }) {
    final values = rival ? (competitor ?? const <double>[]) : mine;
    final seconds = rival ? competitorSeconds : mySeconds;
    final points = rival ? competitorPoints : myPoints;
    return (
      minutes: index < values.length ? values[index] : 0,
      seconds: index < seconds.length ? seconds[index] : null,
      points: index < points.length ? points[index] : null,
    );
  }
}

/// The colors a chart's frame is drawn in, resolved for the active theme by
/// the widget - a [CustomPainter] has no [BuildContext] of its own.
///
/// Only the frame follows the theme: the two series keep their own greens in
/// both themes, as the legend dots beside them do.
class QuranChartPalette {
  const QuranChartPalette({
    required this.axisInk,
    required this.gridLine,
    required this.dayInk,
  });

  factory QuranChartPalette.of(BuildContext context) => QuranChartPalette(
    axisInk: context.textInkColor(const Color(0xFF8E9582)),
    gridLine: context.lineColor(const Color(0xFFE2E7DA)),
    dayInk: context.textInkColor(const Color(0xFF282442)),
  );

  /// The Y-axis numbers.
  final Color axisInk;

  /// The dotted gridlines.
  final Color gridLine;

  /// The day labels under the chart.
  final Color dayInk;

  @override
  bool operator ==(Object other) =>
      other is QuranChartPalette &&
      other.axisInk == axisInk &&
      other.gridLine == gridLine &&
      other.dayInk == dayInk;

  @override
  int get hashCode => Object.hash(axisInk, gridLine, dayInk);
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

/// Where a chart's points land inside it, so its painter and the card laid
/// over the point tapped work off one set of numbers.
class QuranPlotArea {
  const QuranPlotArea({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.maxY,
    this.dayStep,
  });

  /// The weekly and daily charts' frame: points spread across the full width.
  factory QuranPlotArea.spread(Size size, double maxY) => QuranPlotArea(
    left: 34,
    top: 34,
    right: size.width - 8,
    bottom: size.height - 26,
    maxY: maxY,
  );

  /// The monthly chart's: it scrolls, so a point's x is its day index times
  /// [step] and the frame starts at the scrolling content's own left edge.
  factory QuranPlotArea.scrolling(Size size, double maxY, double step) =>
      QuranPlotArea(
        left: 0,
        top: 34,
        right: size.width,
        bottom: size.height - 26,
        maxY: maxY,
        dayStep: step,
      );

  final double left;
  final double top;
  final double right;
  final double bottom;
  final double maxY;

  /// Set on a scrolling chart: the distance between two days.
  final double? dayStep;

  double get width => right - left;
  double get height => bottom - top;

  double xForIndex(int index, int count) {
    final step = dayStep;
    if (step != null) return index * step + 10.0;
    if (count <= 1) return left + width / 2;
    return left + width * (index / (count - 1));
  }

  double yForValue(double value) =>
      maxY <= 0 ? bottom : bottom - height * (value / maxY);

  /// The point nearest to horizontal position [dx].
  int indexAt(double dx, int count) {
    if (count <= 1) return 0;
    final step = dayStep;
    if (step != null) {
      return step <= 0 ? 0 : ((dx - 10.0) / step).round().clamp(0, count - 1);
    }
    final t = width <= 0 ? 0.0 : (dx - left) / width;
    return (t * (count - 1)).round().clamp(0, count - 1);
  }
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
// 0. THE CARD A TAPPED POINT OPENS
// ============================================================================

/// One line of [QuranChartTooltip]: a reader, the time they read that day and
/// the points it earned them.
class QuranChartReading {
  const QuranChartReading({
    required this.color,
    required this.name,
    required this.time,
    this.points,
  });

  /// The series' own colour, so the line matches the line on the chart.
  final Color color;
  final String name;
  final String time;

  /// `null` when the server sent no points for that day.
  final String? points;
}

/// The card a chart shows for the point tapped: nothing is on screen until
/// then, so the chart keeps the design it had and the figures appear only on
/// a tap.
class QuranChartTooltip extends StatelessWidget {
  const QuranChartTooltip({
    super.key,
    required this.title,
    required this.readings,
  });

  final String title;
  final List<QuranChartReading> readings;

  @override
  Widget build(BuildContext context) {
    final ink = context.inkColor(const Color(0xFF2C331B));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      constraints: const BoxConstraints(maxWidth: 190),
      decoration: BoxDecoration(
        color: context.surfaceColor(const Color(0xFFE9F0D2)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          for (final reading in readings) ...[
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: reading.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    reading.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: ink),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  reading.time,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ],
            ),
            if (reading.points case final points?)
              Padding(
                padding: const EdgeInsets.only(left: 13, top: 1),
                child: Text(
                  points,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: context.textInkColor(const Color(0xFF6E7E38)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// The card for day [index] of [data]: each shown reader's time and points.
List<QuranChartReading> quranChartReadings(
  QuranChartData data,
  QuranText t,
  int index, {
  required bool withCompetitor,
}) {
  String time(({double minutes, int? seconds, double? points}) day) =>
      day.seconds == null
      ? t.minutes(day.minutes)
      : t.readingDuration(day.seconds!);
  String? points(({double minutes, int? seconds, double? points}) day) =>
      day.points == null ? null : t.pointValue(day.points!);

  final mine = data.at(index, rival: false);
  final theirs = data.at(index, rival: true);
  return [
    QuranChartReading(
      color: quranMyColor,
      name: data.myName.isEmpty ? t.myPositionLabel : data.myName,
      time: time(mine),
      points: points(mine),
    ),
    if (withCompetitor)
      QuranChartReading(
        color: quranRivalColor,
        name: data.competitorName.isEmpty
            ? t.competitorLabel
            : data.competitorName,
        time: time(theirs),
        points: points(theirs),
      ),
  ];
}

/// The two series' colours, the same ones the legend dots use.
const quranMyColor = Color(0xFF5D7858);
const quranRivalColor = Color(0xFF8F9F4A);

/// Keeps a tooltip inside the chart: [x] is where its point is, [width] how
/// wide the chart is and [cardWidth] the widest the card may be.
double quranTooltipLeft(double x, double width, {double cardWidth = 190}) =>
    (x - cardWidth / 2).clamp(0.0, math.max(0.0, width - cardWidth));

// ============================================================================
// 1. WEEKLY CHART
// ============================================================================

class QuranWeeklyChart extends StatefulWidget {
  const QuranWeeklyChart({
    super.key,
    required this.data,
    this.showCompetitor = true,
  });

  final QuranChartData data;
  final bool showCompetitor;

  @override
  State<QuranWeeklyChart> createState() => _QuranWeeklyChartState();
}

class _QuranWeeklyChartState extends State<QuranWeeklyChart> {
  /// The day whose card is open; nothing is shown until a point is tapped.
  int? _selected;

  @override
  void didUpdateWidget(QuranWeeklyChart old) {
    super.didUpdateWidget(old);
    // A new period's days are not the ones that were tapped.
    if (_selected != null && _selected! >= widget.data.labels.length) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final t = QuranText.of(context);
    final withCompetitor = widget.showCompetitor && data.competitor != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final area = QuranPlotArea.spread(size, data.maxY);
        final count = data.labels.length;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Tapping the open day again closes its card.
          onTapDown: (details) {
            if (count == 0) return;
            final i = area.indexAt(details.localPosition.dx, count);
            setState(() => _selected = _selected == i ? null : i);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: size,
                painter: _WeeklyChartPainter(
                  data: data,
                  number: t.n,
                  showCompetitor: withCompetitor,
                  palette: QuranChartPalette.of(context),
                  selectedIndex: _selected,
                ),
              ),
              if (_selected case final i? when i < count)
                Positioned(
                  left: quranTooltipLeft(area.xForIndex(i, count), size.width),
                  top: math.max(
                    0,
                    area.yForValue(
                          math.max(
                            data.mine[i],
                            withCompetitor ? data.competitor![i] : 0,
                          ),
                        ) -
                        78,
                  ),
                  child: QuranChartTooltip(
                    title: data.labels[i],
                    readings: quranChartReadings(
                      data,
                      t,
                      i,
                      withCompetitor: withCompetitor,
                    ),
                  ),
                ),
            ],
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
    required this.palette,
    this.selectedIndex,
  });

  final QuranChartData data;
  final String Function(Object) number;
  final bool showCompetitor;

  /// The frame's colors for the active theme, from [QuranWeeklyChart].
  final QuranChartPalette palette;

  /// The tapped day, drawn with a bigger marker; null before any tap.
  final int? selectedIndex;

  List<String> get labels => data.labels;
  List<double> get myValues => data.mine;
  List<double> get competitorValues => data.competitor ?? const [];

  @override
  void paint(Canvas canvas, Size size) {
    final maxY = data.maxY;
    final area = QuranPlotArea.spread(size, maxY);
    final chartLeft = area.left;
    final chartRight = area.right;
    final chartTop = area.top;
    final chartBottom = area.bottom;

    // 1. Horizontal dotted lines and Y labels
    for (final level in _levels(maxY)) {
      final y = area.yForValue(level);
      drawChartText(
        canvas,
        _axisLabel(level, number),
        Offset(chartLeft - 6, y),
        color: palette.axisInk,
        fontSize: 10.5,
        align: TextAlign.right,
        anchorRight: true,
        anchorMiddleY: true,
      );
      drawChartDottedLine(
        canvas,
        Offset(chartLeft, y),
        Offset(chartRight, y),
        color: palette.gridLine,
      );
    }

    final count = labels.length;
    if (count == 0 || myValues.length != count) return;
    double xAt(int i) => area.xForIndex(i, count);
    double yAt(double v) => area.yForValue(v);

    // 2. Day labels
    for (var i = 0; i < count; i++) {
      drawChartText(
        canvas,
        labels[i],
        Offset(xAt(i), chartBottom + 8),
        color: palette.dayInk,
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

    // 5. My Position node markers. The tapped one is drawn bigger, so the
    // card that opened plainly belongs to it.
    for (var i = 0; i < myPoints.length; i++) {
      drawReadingNode(canvas, myPoints[i], selected: i == selectedIndex);
    }

    // 6. Competitor badges
    if (withCompetitor) {
      final compPoints = [
        for (var i = 0; i < count; i++)
          Offset(xAt(i), yAt(competitorValues[i])),
      ];
      for (var i = 0; i < compPoints.length; i++) {
        drawCompetitorBadge(canvas, compPoints[i], data.competitorBadge);
        if (i == selectedIndex) {
          drawRivalNode(canvas, compPoints[i]);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyChartPainter oldDelegate) =>
      oldDelegate.showCompetitor != showCompetitor ||
      oldDelegate.data != data ||
      oldDelegate.palette != palette ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.number('1') != number('1');
}

// ============================================================================
// 2. MONTHLY CHART
// ============================================================================

class QuranMonthlyChart extends StatefulWidget {
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
  State<QuranMonthlyChart> createState() => _QuranMonthlyChartState();
}

class _QuranMonthlyChartState extends State<QuranMonthlyChart> {
  /// The day whose card is open; nothing is shown until a point is tapped.
  int? _selected;

  @override
  void didUpdateWidget(QuranMonthlyChart old) {
    super.didUpdateWidget(old);
    if (_selected != null && _selected! >= widget.data.labels.length) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return LayoutBuilder(
      builder: (context, constraints) {
        const leftPad = 34.0;
        final viewportChartWidth = constraints.maxWidth - leftPad - 8.0;
        final dayStep = viewportChartWidth / 10.0;
        final count = data.labels.length;
        final totalScrollWidth = dayStep * math.max(count - 1, 0);
        final t = QuranText.of(context);
        final maxY = data.maxY;
        final withCompetitor =
            widget.showCompetitor && data.competitor?.length == count;

        // The scrolling content's own box, which its points are placed in.
        final contentSize = Size(
          totalScrollWidth + 30,
          constraints.maxHeight - 24,
        );
        final area = QuranPlotArea.scrolling(contentSize, maxY, dayStep);

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
                  palette: QuranChartPalette.of(context),
                ),
              ),
            ),
            Positioned(
              left: leftPad,
              top: 0,
              right: 8,
              bottom: 24,
              child: SingleChildScrollView(
                controller: widget.controller,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // Tapping the open day again closes its card.
                  onTapDown: (details) {
                    if (count == 0) return;
                    final i = area.indexAt(details.localPosition.dx, count);
                    setState(() => _selected = _selected == i ? null : i);
                  },
                  child: SizedBox(
                    width: contentSize.width,
                    height: contentSize.height,
                    // The card lives inside the scrolling content, so it
                    // travels with the day it belongs to.
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(
                          size: contentSize,
                          painter: _MonthlyScrollablePainter(
                            data: data,
                            maxY: maxY,
                            dayStep: dayStep,
                            showCompetitor: withCompetitor,
                            palette: QuranChartPalette.of(context),
                            selectedIndex: _selected,
                          ),
                        ),
                        if (_selected case final i? when i < count)
                          Positioned(
                            left: quranTooltipLeft(
                              area.xForIndex(i, count),
                              contentSize.width,
                            ),
                            top: math.max(
                              0,
                              area.yForValue(
                                    math.max(
                                      data.mine[i],
                                      withCompetitor ? data.competitor![i] : 0,
                                    ),
                                  ) -
                                  78,
                            ),
                            child: QuranChartTooltip(
                              title: data.labels[i],
                              readings: quranChartReadings(
                                data,
                                t,
                                i,
                                withCompetitor: withCompetitor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: leftPad + 4,
              right: 12,
              bottom: 4,
              child: QuranScrollIndicatorBar(progress: widget.scrollProgress),
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
    required this.palette,
  });

  final String Function(Object) number;
  final double maxY;

  final double leftPad;

  /// The frame's colors for the active theme, from [QuranMonthlyChart].
  final QuranChartPalette palette;

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
        color: palette.axisInk,
        fontSize: 10.5,
        align: TextAlign.right,
        anchorRight: true,
        anchorMiddleY: true,
      );
      drawChartDottedLine(
        canvas,
        Offset(leftPad, y),
        Offset(size.width - 8, y),
        color: palette.gridLine,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _YAxisGridPainter oldDelegate) =>
      oldDelegate.maxY != maxY ||
      oldDelegate.palette != palette ||
      oldDelegate.number('1') != number('1');
}

class _MonthlyScrollablePainter extends CustomPainter {
  _MonthlyScrollablePainter({
    required this.data,
    required this.maxY,
    required this.dayStep,
    required this.showCompetitor,
    required this.palette,
    this.selectedIndex,
  });

  final QuranChartData data;
  final double maxY;
  final double dayStep;
  final bool showCompetitor;

  /// The frame's colors for the active theme, from [QuranMonthlyChart].
  final QuranChartPalette palette;

  /// The tapped day, drawn with a bigger marker; null before any tap.
  final int? selectedIndex;

  List<String> get days => data.labels;
  List<double> get myValues => data.mine;
  List<double> get competitorValues => data.competitor ?? const [];

  @override
  void paint(Canvas canvas, Size size) {
    final area = QuranPlotArea.scrolling(size, maxY, dayStep);
    final chartTop = area.top;
    final chartBottom = area.bottom;

    final count = days.length;
    if (count == 0 || myValues.length != count) return;
    double xAt(int i) => area.xForIndex(i, count);
    double yAt(double v) => area.yForValue(v);

    // Day numbers
    for (var i = 0; i < count; i++) {
      drawChartText(
        canvas,
        days[i],
        Offset(xAt(i), chartBottom + 8),
        color: palette.dayInk,
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

    // My Position markers. The tapped one is drawn bigger, so the card that
    // opened plainly belongs to it.
    for (var i = 0; i < myPoints.length; i++) {
      drawReadingNode(canvas, myPoints[i], selected: i == selectedIndex);
    }

    // Competitor badges
    if (showCompetitor) {
      final compPoints = [
        for (var i = 0; i < count; i++)
          Offset(xAt(i), yAt(competitorValues[i])),
      ];
      for (var i = 0; i < compPoints.length; i++) {
        drawCompetitorBadge(canvas, compPoints[i], data.competitorBadge);
        if (i == selectedIndex) {
          drawRivalNode(canvas, compPoints[i]);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyScrollablePainter oldDelegate) =>
      oldDelegate.showCompetitor != showCompetitor ||
      oldDelegate.data != data ||
      oldDelegate.palette != palette ||
      oldDelegate.selectedIndex != selectedIndex ||
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
        color: context.surfaceColor(const Color(0xFFE9F0D2)),
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
                    color: context.surfaceColor(const Color(0xFFD0E09B)),
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

class QuranDailyChart extends StatefulWidget {
  const QuranDailyChart({
    super.key,
    required this.mine,
    this.competitor,
    this.competitorBadge = '',
    this.showCompetitor = true,
    this.readings = const [],
  });

  /// Minutes read today, by the user and by the compared user.
  final double mine;
  final double? competitor;
  final String competitorBadge;
  final bool showCompetitor;

  /// Today's figures for the card a tap opens; empty leaves the chart as it
  /// is, with nothing to open.
  final List<QuranChartReading> readings;

  @override
  State<QuranDailyChart> createState() => _QuranDailyChartState();
}

class _QuranDailyChartState extends State<QuranDailyChart> {
  /// Whether today's card is open; closed until the peak is tapped.
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = QuranText.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final area = QuranPlotArea.spread(
          size,
          quranChartMax([
            widget.mine,
            ?(widget.showCompetitor ? widget.competitor : null),
          ]),
        );
        // The apex the painter draws my mountain at.
        final apexX = area.left + area.width * 0.44;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.readings.isEmpty
              ? null
              : (_) => setState(() => _open = !_open),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: size,
                painter: _DailyChartPainter(
                  mine: widget.mine,
                  competitor: widget.showCompetitor ? widget.competitor : null,
                  competitorBadge: widget.competitorBadge,
                  number: t.n,
                  caption: t.todaysValue,
                  palette: QuranChartPalette.of(context),
                  marked: _open,
                ),
              ),
              if (_open)
                Positioned(
                  left: quranTooltipLeft(apexX, size.width),
                  top: math.max(0, area.yForValue(widget.mine) - 78),
                  child: QuranChartTooltip(
                    title: t.todaysValue,
                    readings: widget.readings,
                  ),
                ),
            ],
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
    required this.palette,
    this.marked = false,
  });

  final double mine;
  final double? competitor;
  final String competitorBadge;
  final String Function(Object) number;
  final String caption;

  /// The frame's colors for the active theme, from [QuranDailyChart].
  final QuranChartPalette palette;

  /// Whether today's card is open, which puts a marker on the peak.
  final bool marked;

  @override
  void paint(Canvas canvas, Size size) {
    final maxY = quranChartMax([mine, ?competitor]);
    final area = QuranPlotArea.spread(size, maxY);
    final chartLeft = area.left;
    final chartRight = area.right;
    final chartBottom = area.bottom;
    final chartWidth = area.width;
    final chartHeight = area.height;

    // Grid lines and Y labels
    for (final level in _levels(maxY)) {
      final y = area.yForValue(level);
      drawChartText(
        canvas,
        _axisLabel(level, number),
        Offset(chartLeft - 6, y),
        color: palette.axisInk,
        fontSize: 10.5,
        align: TextAlign.right,
        anchorRight: true,
        anchorMiddleY: true,
      );
      drawChartDottedLine(
        canvas,
        Offset(chartLeft, y),
        Offset(chartRight, y),
        color: palette.gridLine,
      );
    }

    // Centered label
    drawChartText(
      canvas,
      caption,
      Offset(chartLeft + chartWidth / 2, chartBottom + 8),
      color: palette.dayInk,
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

    // The peak carries a marker while its card is open.
    if (marked) {
      drawReadingNode(canvas, Offset(myApexX, myApexY), selected: true);
    }
  }

  @override
  bool shouldRepaint(covariant _DailyChartPainter oldDelegate) =>
      oldDelegate.mine != mine ||
      oldDelegate.competitor != competitor ||
      oldDelegate.palette != palette ||
      oldDelegate.marked != marked ||
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

/// A node on my reading line: a dot in a soft halo, bigger while [selected].
void drawReadingNode(Canvas canvas, Offset at, {bool selected = false}) {
  canvas.drawCircle(
    at,
    selected ? 9.5 : 7.5,
    Paint()..color = quranMyColor.withValues(alpha: selected ? 0.3 : 0.22),
  );
  canvas.drawCircle(at, selected ? 4.5 : 3.5, Paint()..color = quranMyColor);
}

/// The same marker on the compared reader's line, so their row in the card
/// points at a visible place on the chart too.
void drawRivalNode(Canvas canvas, Offset at) {
  canvas.drawCircle(
    at,
    9.5,
    Paint()..color = quranRivalColor.withValues(alpha: 0.3),
  );
  canvas.drawCircle(at, 4.5, Paint()..color = quranRivalColor);
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
    style: TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamilyFallback: appFontFamilyFallback,
    ),
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
