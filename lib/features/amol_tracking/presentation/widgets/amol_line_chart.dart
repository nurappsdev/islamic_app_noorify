import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_context.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_state.dart';

import 'amol_chart_painters.dart';
import 'amol_dashboard_utils.dart';
import 'amol_score_bubble.dart';
import 'amol_score_tooltip.dart';

class AmolLineChart extends StatefulWidget {
  const AmolLineChart({
    super.key,
    required this.categories,
    required this.values,
    required this.myLabel,
    required this.competitorValues,
    required this.competitorLabel,
    required this.maxY,
    required this.columnLayout,
    this.verticalLabels = false,
    this.scrollable = false,
  });

  final List<String> categories;
  final List<double> values;

  /// The local signed-in user's initials, shown on a pill at each of
  /// [values]'s points (mirrors [competitorLabel]'s pill).
  final String myLabel;

  /// The nearest competitor's score per category, `null` where the server
  /// has none for that pillar (no bubble is drawn there).
  final List<double?> competitorValues;
  final String competitorLabel;
  final double maxY;

  /// True for the weekly and monthly tabs: draws the same per-pillar
  /// points as overlapping columns ([AmolBarChartPainter]) instead of a
  /// connected line ([AmolLineChartPainter]), matching the Hadith
  /// dashboard's weekly bar chart. Everything else (grid, axis labels,
  /// score bubbles, tap-to-select tooltip) is shared and unaffected by
  /// this flag.
  final bool columnLayout;

  /// Monthly's vertical category labels instead of daily/weekly's diagonal
  /// ones (reference image). Only meaningful together with [columnLayout].
  final bool verticalLabels;

  /// Wraps the chart in horizontal scrolling and widens it to fit every
  /// category at a readable column width, instead of squeezing them all
  /// into the viewport. Monthly only — it can have more categories than
  /// daily/weekly's fixed 7-pillar list ever does.
  final bool scrollable;

  @override
  State<AmolLineChart> createState() => _AmolLineChartState();
}

class _AmolLineChartState extends State<AmolLineChart> {
  /// Which category column is showing its tap tooltip; `null` when none is.
  int? _selectedIndex;

  void _select(int index) {
    setState(() => _selectedIndex = _selectedIndex == index ? null : index);
  }

  /// The widest category label at the chart's label font size — monthly's
  /// vertical labels need the bottom plot margin sized to this (rotated 90°,
  /// a label's width becomes its vertical extent), so nothing is truncated
  /// regardless of how long a category's name is.
  static double _verticalLabelExtent(List<String> categories) {
    var maxWidth = 0.0;
    for (final category in categories) {
      final painter = TextPainter(
        text: TextSpan(
          text: category,
          style: TextStyle(fontSize: 9.sp),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (painter.width > maxWidth) maxWidth = painter.width;
    }
    return maxWidth;
  }

  /// The widest y-axis tick label at the chart's label font size — needed
  /// so the left gutter (this state's `build`'s `plotLeft`) can grow
  /// enough to keep 4-digit-plus values (1,000+) fully on-screen instead
  /// of clipping against the chart's left edge.
  static double _tickLabelExtent(List<double> ticks, AppLanguage language) {
    var maxWidth = 0.0;
    for (final tick in ticks) {
      final painter = TextPainter(
        text: TextSpan(
          text: localizeDigits(tick.round().toString(), language),
          style: TextStyle(fontSize: 9.sp),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (painter.width > maxWidth) maxWidth = painter.width;
    }
    return maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    // Weekly/monthly bar charts get their own fully data-driven y-axis
    // (see `niceAmolAxisTicks`) instead of the line chart's fixed division
    // of `widget.maxY`; `tickValues.last` is then the bar chart's axis
    // ceiling everywhere it's needed (point scaling, grid, labels).
    final tickValues = widget.columnLayout
        ? niceAmolAxisTicks(widget.values, widget.competitorValues)
        : null;
    final axisMaxY = tickValues?.last ?? widget.maxY;
    final language = languageOf(context);
    // Grows past its normal width only when a tick label (e.g. "1,250")
    // genuinely needs the room, so small values look exactly as before.
    final plotLeft = tickValues == null
        ? 24.w
        : math.max(24.w, _tickLabelExtent(tickValues, language) + 10.w);
    final plotTop = 30.h;
    final plotRight = 6.w;
    final plotBottom = widget.verticalLabels
        ? _verticalLabelExtent(widget.categories) + 16.h
        : 48.h;
    // The plotted area always gets the same vertical room (the original
    // 240.h total, minus its 30.h top and 48.h bottom); only the label band
    // below it grows for monthly's taller vertical labels.
    final height = plotTop + 162.h + plotBottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final categoryCount = widget.categories.length;
        // Wide enough for each column's bar and vertical label to have
        // breathing room; scrolls past that instead of squeezing every
        // category into the viewport when there are many of them.
        final minColumnWidth = 56.w;
        final width = widget.scrollable
            ? math.max(constraints.maxWidth, categoryCount * minColumnWidth)
            : constraints.maxWidth;
        final plotRect = Rect.fromLTWH(
          plotLeft,
          plotTop,
          (width - plotLeft - plotRight).clamp(0.0, double.infinity),
          (height - plotTop - plotBottom).clamp(0.0, double.infinity),
        );
        final points = _computePoints(
          plotRect,
          widget.values,
          axisMaxY,
          slotted: widget.columnLayout,
        ).cast<Offset>();
        final competitorPoints = _computePoints(
          plotRect,
          widget.competitorValues,
          axisMaxY,
          slotted: widget.columnLayout,
        );
        // Mirrors `_computePoints`' own spacing for this layout, so the
        // tap zones below land exactly on the columns they're meant for.
        final stepX = widget.columnLayout
            ? (categoryCount > 0 ? plotRect.width / categoryCount : 0.0)
            : (categoryCount > 1
                  ? plotRect.width / (categoryCount - 1)
                  : plotRect.width);
        final selected = _selectedIndex;

        final chart = SizedBox(
          height: height,
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: widget.columnLayout
                    ? AmolBarChartPainter(
                        plotRect: plotRect,
                        categories: widget.categories,
                        points: points,
                        competitorPoints: competitorPoints,
                        tickValues: tickValues!,
                        language: language,
                        selectedIndex: selected,
                        verticalLabels: widget.verticalLabels,
                      )
                    : AmolLineChartPainter(
                        plotRect: plotRect,
                        categories: widget.categories,
                        points: points,
                        competitorPoints: competitorPoints,
                        maxY: widget.maxY,
                        language: language,
                        selectedIndex: selected,
                      ),
              ),
              // Tapping the empty chart background (outside any category's
              // column) dismisses the tooltip/highlight.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => setState(() => _selectedIndex = null),
                ),
              ),
              for (var i = 0; i < categoryCount; i++)
                Positioned(
                  // Centered on `points[i].dx` — the same x the bar/circle
                  // for this column actually renders at — rather than a
                  // separately re-derived formula that could (and once
                  // did) drift out of sync with it.
                  left: (points[i].dx - stepX / 2).clamp(0.0, width),
                  top: 0,
                  width: stepX,
                  height: plotRect.bottom,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _select(i),
                  ),
                ),
              for (var i = 0; i < competitorPoints.length; i++)
                if (competitorPoints[i] != null)
                  Positioned(
                    // Column layout (weekly/monthly): the circle sits at
                    // the bar's own top-left corner, i.e. exactly where
                    // that series' progress reaches — clamped the same way
                    // the painter clamps the bar's own left edge, so the
                    // two always land on the same pixel even for the
                    // first/last column. Line layout (daily) keeps its own
                    // point marker drawn by the painter, so the label
                    // floats just above it instead of covering it.
                    left: widget.columnLayout
                        ? (competitorPoints[i]!.dx -
                                  AmolBarChartPainter.barHalfWidth(
                                    categoryCount,
                                    plotRect.width,
                                  ))
                              .clamp(plotRect.left, plotRect.right)
                        : competitorPoints[i]!.dx,
                    top: widget.columnLayout
                        ? competitorPoints[i]!.dy.clamp(0.0, height)
                        : (competitorPoints[i]!.dy - 32.h).clamp(0.0, height),
                    child: FractionalTranslation(
                      translation: widget.columnLayout
                          ? const Offset(-0.5, -0.5)
                          : const Offset(-0.5, 0),
                      child: AmolScoreBubble(
                        label: widget.competitorLabel,
                        pillColor: AmolLineChartPainter.competitorLineColor,
                        solid: widget.columnLayout,
                      ),
                    ),
                  ),
              for (var i = 0; i < points.length; i++)
                Positioned(
                  left: widget.columnLayout
                      ? (points[i].dx -
                                AmolBarChartPainter.barHalfWidth(
                                  categoryCount,
                                  plotRect.width,
                                ))
                            .clamp(plotRect.left, plotRect.right)
                      : points[i].dx,
                  top: widget.columnLayout
                      ? points[i].dy.clamp(0.0, height)
                      : (points[i].dy + 8.h).clamp(0.0, height),
                  child: FractionalTranslation(
                    translation: widget.columnLayout
                        ? const Offset(-0.5, -0.5)
                        : const Offset(-0.5, 0),
                    child: AmolScoreBubble(
                      label: widget.myLabel,
                      pillColor: AmolLineChartPainter.lineColor,
                      solid: widget.columnLayout,
                    ),
                  ),
                ),
              // Tapping any column (daily/weekly/monthly alike) shows the
              // same my/competitor points tooltip.
              if (selected != null)
                Positioned(
                  left: points[selected].dx.clamp(
                    56.w,
                    (width - 56.w).clamp(56.w, double.infinity),
                  ),
                  top: _tooltipTop(points, competitorPoints, selected),
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0),
                    child: AmolScoreTooltip(
                      title: widget.categories[selected],
                      myLabel: widget.myLabel,
                      myScore: widget.values[selected],
                      competitorLabel: widget.competitorLabel,
                      competitorScore: selected < widget.competitorValues.length
                          ? widget.competitorValues[selected]
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        );

        if (!widget.scrollable) return chart;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: chart,
        );
      },
    );
  }

  /// Anchors the tooltip just above whichever of the two lines is higher
  /// (smaller `dy`) at [index], so it never covers either marker.
  double _tooltipTop(
    List<Offset> points,
    List<Offset?> competitorPoints,
    int index,
  ) {
    final myY = index < points.length ? points[index].dy : double.infinity;
    final competitorY = index < competitorPoints.length
        ? competitorPoints[index]?.dy ?? double.infinity
        : double.infinity;
    final topY = myY < competitorY ? myY : competitorY;
    return (topY - 64.h).clamp(0.0, double.infinity);
  }

  /// Maps [values] onto [rect] using [maxY] as the y-axis ceiling. A `null`
  /// entry (only possible for competitor values) stays `null` in the
  /// result, so its bubble is skipped.
  ///
  /// [slotted] (bar charts, i.e. [AmolLineChart.columnLayout]) divides
  /// [rect] into `values.length` equal slots and centers each point in its
  /// own slot, so the first/last bars get the same breathing room on both
  /// sides as every bar in between. Without it (the default, used by the
  /// line chart), the first and last points sit exactly on [rect]'s left
  /// and right edges instead — correct for a line chart's endpoints, but
  /// for a bar chart it means the first/last bar's own half-width always
  /// extends past the plot edge and gets clamped there, rendering as a
  /// visibly thinner, lopsided bar whose score bubble (anchored to the
  /// *unclamped* point) then drifts away from the bar's actual edge.
  static List<Offset?> _computePoints(
    Rect rect,
    List<double?> values,
    double maxY, {
    bool slotted = false,
  }) {
    final count = values.length;
    final stepX = slotted
        ? (count > 0 ? rect.width / count : 0.0)
        : (count > 1 ? rect.width / (count - 1) : 0.0);
    return [
      for (var i = 0; i < count; i++)
        if (values[i] == null)
          null
        else
          Offset(
            rect.left + stepX * (slotted ? i + 0.5 : i.toDouble()),
            rect.bottom - (values[i]! / maxY).clamp(0.0, 1.0) * rect.height,
          ),
    ];
  }
}
