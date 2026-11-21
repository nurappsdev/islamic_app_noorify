import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';

/// The palette the three reading-dashboard charts share (`devImg/img_41.png`).
abstract final class DuaChartColors {
  /// The signed-in user's own share.
  static const mine = Color(0xFFA8B657);

  /// The same share while its bar or slice is selected.
  static const mineStrong = Color(0xFF7F9139);

  /// What the user is measured against — the lighter of the two layers.
  static const competitor = Color(0xFFDCE8B5);

  /// The unfilled rest of a bar's track.
  static const track = Color(0xFFF1F5E3);
  static const axis = Color(0xFF91A168);
  static const tooltipSurface = Color(0xFFE6EEC6);
  static const tooltipInk = Color(0xFF364027);
}

/// A chart axis with five evenly spaced, round ticks that covers [rawMax].
///
/// The design draws `0 … 1000`; the real axis follows the data instead, so a
/// quiet week is not flattened against the bottom of a fixed 1000 scale.
({double max, List<int> ticks}) duaChartAxis(int rawMax) {
  const units = <int>[1, 2, 5, 10, 15, 25, 50, 100, 250, 500, 1000, 2500, 5000];
  final target = rawMax <= 0 ? 1 : (rawMax / 4).ceil();
  final step = units.firstWhere(
    (unit) => unit >= target,
    orElse: () => ((target + 999) ~/ 1000) * 1000,
  );
  return (
    max: (step * 4).toDouble(),
    ticks: [for (var i = 0; i <= 4; i++) step * i],
  );
}

/// The competitor's share of [mine], scaled by the window's own
/// `myPositionPercentage : competitorPercentage` split.
///
/// The dashboard answer carries no per-day competitor figure — only that one
/// whole-window ratio — so every bar's lighter layer is this projection of
/// it, not a value the server sent for that day.
int duaCompetitorValue(
  int mine, {
  required double myPercentage,
  required double competitorPercentage,
}) {
  if (mine <= 0 || myPercentage <= 0 || competitorPercentage <= 0) return 0;
  return (mine * competitorPercentage / myPercentage).round();
}

/// One column (weekly) or row (monthly) of a bar chart.
class DuaChartBar {
  const DuaChartBar({
    required this.label,
    required this.mine,
    required this.competitor,
    String? title,
  }) : title = title ?? label;

  /// What the axis prints beside the bar (`Sat`, `30`).
  final String label;

  /// What the tooltip is headed with — the same as [label] unless the bar
  /// stands for a span the axis cannot spell out (`22–30`).
  final String title;

  /// The user's own minutes for this bar.
  final int mine;

  /// The competitor's, from [duaCompetitorValue].
  final int competitor;

  int get highest => math.max(mine, competitor);
}

/// A line of [DuaChartTooltip]: either a plain sentence, or a legend dot with
/// a label and the value it stands for.
class DuaTooltipLine {
  const DuaTooltipLine.text(this.text)
    : color = null,
      value = null,
      indented = false;

  /// A quieter line under the metric above it — the server's own
  /// `pointsText`, which already reads `Point : 6/10`.
  const DuaTooltipLine.note(this.text)
    : color = null,
      value = null,
      indented = true;

  const DuaTooltipLine.metric({
    required this.color,
    required this.text,
    required this.value,
  }) : indented = false;

  final String text;
  final String? value;
  final Color? color;
  final bool indented;
}

/// The floating card a chart shows for the slice, bar or week tapped.
class DuaChartTooltip extends StatelessWidget {
  const DuaChartTooltip({super.key, required this.title, required this.lines});

  final String title;
  final List<DuaTooltipLine> lines;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 9.h),
    constraints: BoxConstraints(maxWidth: 148.w),
    decoration: BoxDecoration(
      color: context.surfaceColor(DuaChartColors.tooltipSurface),
      borderRadius: BorderRadius.circular(14.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .18),
          blurRadius: 9.r,
          offset: Offset(0, 3.h),
        ),
      ],
    ),
    // The card sits in a Positioned with no width of its own, so the rows'
    // Spacer needs a finite one: IntrinsicWidth supplies it.
    child: IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A card whose rows already name both sides needs no heading.
          if (title.isNotEmpty)
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: context.inkColor(DuaChartColors.tooltipInk),
              ),
            ),
          for (final (index, line) in lines.indexed) ...[
            if (index > 0 || title.isNotEmpty)
              SizedBox(height: line.indented ? 1.h : 4.h),
            _TooltipLine(line: line),
          ],
        ],
      ),
    ),
  );
}

class _TooltipLine extends StatelessWidget {
  const _TooltipLine({required this.line});
  final DuaTooltipLine line;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 9.5.sp,
      color: context.inkColor(DuaChartColors.tooltipInk),
    );
    if (line.color case final color?) {
      return Row(
        children: [
          Container(
            width: 7.r,
            height: 7.r,
            decoration: BoxDecoration(
              color: context.surfaceColor(color),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              line.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            line.value ?? '',
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      );
    }
    return Padding(
      padding: EdgeInsets.only(left: line.indented ? 12.w : 0),
      child: Text(
        line.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: line.indented
            ? style.copyWith(
                fontSize: 9.sp,
                color: context.textInkColor(DuaChartColors.axis),
              )
            : style,
      ),
    );
  }
}

/// Daily view: a donut split between the user's share and the competitor's,
/// which opens [tooltip] when tapped.
class DuaDonutChart extends StatefulWidget {
  const DuaDonutChart({
    super.key,
    required this.myPercentage,
    required this.competitorPercentage,
    required this.tooltip,
  });

  final double myPercentage;
  final double competitorPercentage;
  final Widget tooltip;

  @override
  State<DuaDonutChart> createState() => _DuaDonutChartState();
}

class _DuaDonutChartState extends State<DuaDonutChart> {
  var _open = true;

  @override
  Widget build(BuildContext context) {
    final mine = widget.myPercentage.clamp(0.0, 100.0);
    final other = widget.competitorPercentage.clamp(0.0, 100.0);
    // The two shares are drawn against their own total, so a response whose
    // halves do not add up to 100 still fills the ring.
    final total = mine + other;
    final fraction = total <= 0 ? 0.0 : mine / total;

    return SizedBox(
      height: 212.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _open = !_open),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: fraction),
                builder: (context, value, _) => CustomPaint(
                  size: Size(190.w, 190.w),
                  painter: _DuaDonutPainter(
                    fraction: value,
                    mine: context.surfaceColor(DuaChartColors.mine),
                    competitor: context.surfaceColor(DuaChartColors.competitor),
                    knob: context.surfaceColor(Colors.white),
                  ),
                ),
              ),
            ),
          ),
          if (_open) Positioned(right: 0, top: 10.h, child: widget.tooltip),
        ],
      ),
    );
  }
}

class _DuaDonutPainter extends CustomPainter {
  const _DuaDonutPainter({
    required this.fraction,
    required this.mine,
    required this.competitor,
    required this.knob,
  });

  final double fraction;
  final Color mine;
  final Color competitor;
  final Color knob;

  /// The ring opens at the top right, as in the design, rather than closing
  /// into a full circle.
  static const _start = -math.pi * .35;
  static const _sweep = math.pi * 1.78;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .36;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .2
      ..strokeCap = StrokeCap.round;

    paint.color = competitor;
    canvas.drawArc(rect, _start, _sweep, false, paint);
    paint.color = mine;
    canvas.drawArc(rect, _start, _sweep * fraction, false, paint);

    // The marker sits where the user's share ends — the point the tooltip
    // describes.
    final angle = _start + _sweep * fraction;
    final knobCenter =
        center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(
      knobCenter,
      size.shortestSide * .035,
      Paint()..color = knob,
    );
  }

  @override
  bool shouldRepaint(covariant _DuaDonutPainter old) =>
      old.fraction != fraction ||
      old.mine != mine ||
      old.competitor != competitor ||
      old.knob != knob;
}

/// Weekly view: one rounded column per day, the user's minutes in front of
/// the competitor's. Tapping a column opens that day's tooltip.
class DuaWeeklyBarChart extends StatefulWidget {
  const DuaWeeklyBarChart({
    super.key,
    required this.bars,
    required this.tooltipBuilder,
  });

  final List<DuaChartBar> bars;

  /// Builds the card for the bar tapped, given its place in [bars].
  final Widget Function(int index, DuaChartBar bar) tooltipBuilder;

  @override
  State<DuaWeeklyBarChart> createState() => _DuaWeeklyBarChartState();
}

class _DuaWeeklyBarChartState extends State<DuaWeeklyBarChart> {
  int? _selected;

  @override
  void didUpdateWidget(covariant DuaWeeklyBarChart old) {
    super.didUpdateWidget(old);
    if (_selected != null && _selected! >= widget.bars.length) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bars = widget.bars;
    if (bars.isEmpty) return SizedBox(height: 212.h);
    final axis = duaChartAxis(
      bars.fold<int>(0, (value, bar) => math.max(value, bar.highest)),
    );

    return SizedBox(
      height: 212.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 26.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final tick in axis.ticks.reversed)
                  Text(
                    context.localizedDigits('$tick'),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: context.textInkColor(DuaChartColors.axis),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slot = constraints.maxWidth / bars.length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: [
                        for (var index = 0; index < bars.length; index++)
                          Expanded(
                            child: _WeeklyColumn(
                              bar: bars[index],
                              axisMax: axis.max,
                              selected: _selected == index,
                              onTap: () => setState(
                                () => _selected = _selected == index
                                    ? null
                                    : index,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_selected case final index?)
                      Positioned(
                        top: 0,
                        left: _tooltipLeft(
                          index: index,
                          slot: slot,
                          width: constraints.maxWidth,
                        ),
                        child: widget.tooltipBuilder(index, bars[index]),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Keeps the tooltip centred over its column without letting it run off
  /// either edge of the plot area.
  double _tooltipLeft({
    required int index,
    required double slot,
    required double width,
  }) {
    final tooltipWidth = 148.w;
    final centred = slot * index + slot / 2 - tooltipWidth / 2;
    return centred.clamp(0.0, math.max(0.0, width - tooltipWidth));
  }
}

class _WeeklyColumn extends StatelessWidget {
  const _WeeklyColumn({
    required this.bar,
    required this.axisMax,
    required this.selected,
    required this.onTap,
  });

  final DuaChartBar bar;
  final double axisMax;
  final bool selected;
  final VoidCallback onTap;

  double _factor(int value) =>
      axisMax <= 0 ? 0 : (value / axisMax).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: context.surfaceColor(DuaChartColors.track),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                // The competitor's layer first, the user's own in front of
                // it — the two colours the tooltip names.
                _Layer(
                  factor: _factor(bar.competitor),
                  color: DuaChartColors.competitor,
                ),
                _Layer(
                  factor: _factor(bar.mine),
                  color: selected
                      ? DuaChartColors.mineStrong
                      : DuaChartColors.mine,
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            bar.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: context.textInkColor(DuaChartColors.axis),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Layer extends StatelessWidget {
  const _Layer({required this.factor, required this.color});

  final double factor;
  final Color color;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: factor,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: context.surfaceColor(color),
        borderRadius: BorderRadius.circular(8.r),
      ),
    ),
  );
}

/// One week of a month, as the monthly view groups the returned days.
class DuaMonthBucket {
  const DuaMonthBucket({
    required this.fromDay,
    required this.toDay,
    required this.minutes,
    required this.duas,
    this.dayLabel = '',
  });

  /// The day the week starts after, so the rows read `0–7`, `7–14`, …
  final int fromDay;
  final int toDay;
  final int minutes;
  final int duas;

  /// Set only when the bucket is a single day (see [duaMonthlyBuckets]); the
  /// server's own `Sat` / `Sun` label for it.
  final String dayLabel;

  bool get isSingleDay => dayLabel.isNotEmpty;
}

/// Groups a month of `weeklyActivity.days` into its four week rows — `0–7`,
/// `7–14`, `14–21` and `21–` the last day of that month.
///
/// The field is named `weeklyActivity` whatever the timeframe, though, so an
/// answer covering two weeks or less would collapse into a single row; each
/// returned day then keeps a row of its own instead.
List<DuaMonthBucket> duaMonthlyBuckets(List<DuaDashboardActivityDay> days) {
  final dated = [
    for (final day in days)
      if (day.dayOfMonth > 0) day,
  ];
  final span = dated.isEmpty
      ? 0
      : dated.map((day) => day.dayOfMonth).reduce(math.max) -
            dated.map((day) => day.dayOfMonth).reduce(math.min);
  if (span <= 14) {
    return [
      for (final day in days)
        DuaMonthBucket(
          fromDay: day.dayOfMonth,
          toDay: day.dayOfMonth,
          minutes: day.minutes,
          duas: day.duas,
          dayLabel: day.label.isNotEmpty ? day.label : '${day.dayOfMonth}',
        ),
    ];
  }

  final lastDay = _lastDayOfMonth(dated);
  final bounds = <(int, int)>[(0, 7), (7, 14), (14, 21), (21, lastDay)];
  return [
    for (final (from, to) in bounds)
      () {
        final inWeek = dated.where(
          (day) => day.dayOfMonth > from && day.dayOfMonth <= to,
        );
        return DuaMonthBucket(
          fromDay: from,
          toDay: to,
          minutes: inWeek.fold<int>(0, (value, day) => value + day.minutes),
          duas: inWeek.fold<int>(0, (value, day) => value + day.duas),
        );
      }(),
  ];
}

/// The real length of the month the window falls in, so the last row reads
/// `21–30` or `21–31` rather than stopping at the last day that had reading.
int _lastDayOfMonth(List<DuaDashboardActivityDay> dated) {
  final anchor = DateTime.tryParse(dated.first.date);
  if (anchor != null) return DateTime(anchor.year, anchor.month + 1, 0).day;
  return math.max(28, dated.map((day) => day.dayOfMonth).reduce(math.max));
}

/// The day a server-labelled period ends on (`1-6` -> `6`), which is what
/// the monthly axis prints; the full label stays for the tooltip's title.
/// A label with no number in it is used as it stands.
String duaPeriodAxisLabel(String label) {
  final numbers = RegExp(r'\d+').allMatches(label);
  return numbers.isEmpty ? label : numbers.last.group(0)!;
}

/// The width the monthly view's day labels and its `0` baseline share.
double get _labelWidth => 40.w;

/// Monthly view: one horizontal bar per week of the month, newest week at the
/// top, with the value axis along the bottom.
class DuaMonthlyBarChart extends StatefulWidget {
  const DuaMonthlyBarChart({
    super.key,
    required this.bars,
    required this.tooltipBuilder,
  });

  final List<DuaChartBar> bars;

  /// Builds the card for the bar tapped, given its place in [bars].
  final Widget Function(int index, DuaChartBar bar) tooltipBuilder;

  @override
  State<DuaMonthlyBarChart> createState() => _DuaMonthlyBarChartState();
}

class _DuaMonthlyBarChartState extends State<DuaMonthlyBarChart> {
  int? _selected;

  @override
  void didUpdateWidget(covariant DuaMonthlyBarChart old) {
    super.didUpdateWidget(old);
    if (_selected != null && _selected! >= widget.bars.length) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bars = widget.bars;
    if (bars.isEmpty) return SizedBox(height: 212.h);
    final axis = duaChartAxis(
      bars.fold<int>(0, (value, bar) => math.max(value, bar.highest)),
    );
    // Top row is the last week of the month, matching the design's axis.
    final rows = bars.reversed.toList(growable: false);

    return SizedBox(
      height: 212.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (var index = 0; index < rows.length; index++)
                      Expanded(
                        child: _MonthlyRow(
                          bar: rows[index],
                          axisMax: axis.max,
                          selected: _selected == index,
                          onTap: () => setState(
                            () => _selected = _selected == index ? null : index,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  // The day axis' own baseline, under the row labels.
                  SizedBox(
                    width: _labelWidth,
                    child: Text(
                      context.localizedDigits('0'),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        color: context.textInkColor(DuaChartColors.axis),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final tick in axis.ticks)
                          Text(
                            context.localizedDigits('$tick'),
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: context.textInkColor(DuaChartColors.axis),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_selected case final index?)
            Positioned(
              right: 4.w,
              top: index == 0 ? 6.h : 0,
              child: widget.tooltipBuilder(
                bars.length - 1 - index,
                rows[index],
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthlyRow extends StatelessWidget {
  const _MonthlyRow({
    required this.bar,
    required this.axisMax,
    required this.selected,
    required this.onTap,
  });

  final DuaChartBar bar;
  final double axisMax;
  final bool selected;
  final VoidCallback onTap;

  double _factor(int value) =>
      axisMax <= 0 ? 0 : (value / axisMax).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Row(
      children: [
        SizedBox(
          width: _labelWidth,
          child: Text(
            context.localizedDigits(bar.label),
            textAlign: TextAlign.right,
            maxLines: 1,
            style: TextStyle(
              fontSize: 9.5.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: context.textInkColor(DuaChartColors.axis),
            ),
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: SizedBox(
            height: 22.h,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: context.surfaceColor(DuaChartColors.track),
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                ),
                _WideLayer(
                  factor: _factor(bar.competitor),
                  color: DuaChartColors.competitor,
                ),
                _WideLayer(
                  factor: _factor(bar.mine),
                  color: selected
                      ? DuaChartColors.mineStrong
                      : DuaChartColors.mine,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _WideLayer extends StatelessWidget {
  const _WideLayer({required this.factor, required this.color});

  final double factor;
  final Color color;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: factor,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: context.surfaceColor(color),
        borderRadius: BorderRadius.circular(11.r),
      ),
    ),
  );
}
