import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/amol_tracking/data/datasources/amol_analytics_remote_data_source.dart';
import 'package:islami_app_noorify/features/amol_tracking/data/repositories/amol_analytics_repository_impl.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/usecases/get_amol_analytics_graph.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/bloc/amol_dashboard_bloc.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/widgets/amol_shared_widgets.dart';

enum _AmolPeriod { daily, weekly, monthly }

/// `pillarKey` order the chart's x-axis renders in — matches
/// `GET /amol/tracker/daily`'s pillars and the `categories` list below.
const _pillarOrder = [
  'fardh_prayer',
  'sunnah_witr',
  'quran',
  'nafl_salat',
  'hadith',
  'quiz',
  'nafl_and_more',
];

String _formatPoints(num value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

/// The competitor bubble is a small pill, so a full server-given name (e.g.
/// "Khalid Saifullah") is shortened to initials (e.g. "KS") to fit it.
String _initials(String name, {required String fallback}) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final letters = words.map((w) => w[0].toUpperCase()).take(2).join();
  return letters.isEmpty ? fallback : letters;
}

/// The current calendar month plus the 11 before it, newest first, for the
/// monthly tab's month-picker dropdown.
List<DateTime> _lastTwelveMonths(DateTime today) => [
  for (var i = 0; i < 12; i++) DateTime(today.year, today.month - i),
];

extension on _AmolPeriod {
  String label(AppText appText) => switch (this) {
    _AmolPeriod.daily => appText.daily,
    _AmolPeriod.weekly => appText.weekly,
    _AmolPeriod.monthly => appText.monthly,
  };

  Duration get step => switch (this) {
    _AmolPeriod.daily => const Duration(days: 1),
    _AmolPeriod.weekly => const Duration(days: 7),
    _AmolPeriod.monthly => const Duration(days: 30),
  };
}

class AmolDashboardScreen extends StatelessWidget {
  const AmolDashboardScreen({super.key, this.now});

  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AmolDashboardBloc(
        GetAmolAnalyticsGraph(
          AmolAnalyticsRepositoryImpl(AmolAnalyticsRemoteDataSourceImpl()),
        ),
        now: now,
      )..add(const LoadGraph()),
      child: const _AmolDashboardView(),
    );
  }
}

class _AmolDashboardView extends StatelessWidget {
  const _AmolDashboardView();

  // Shown before the first `GET /amol/analytics/graph` response lands.
  static const _fallbackMyPosition = [6.0, 10.0, 2.0, 9.0, 2.0, 10.0, 3.0];
  static const _fallbackCompetitorValues = [6.0, 9.0, null, 8.0, null, 11.0, null];
  static const _fallbackPoints = 27;
  static const _fallbackCompetitorLabel = 'Ab';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AmolDashboardBloc>().state;
    final bloc = context.read<AmolDashboardBloc>();
    final appText = AppText.of(context);
    final period = _AmolPeriod.values[state.selectedPeriod];
    final categories = [
      appText.categoryFardhPrayer,
      appText.categorySunnahAndWitr,
      appText.categoryQuran,
      appText.categoryNaflSalat,
      appText.categoryHadith,
      appText.categoryQuiz,
      appText.categoryNaflAndMore,
    ];
    final graph = state.graph;
    final values = graph == null
        ? _fallbackMyPosition
        : [for (final key in _pillarOrder) graph.valueFor(key).toDouble()];
    final competitorValues = graph == null
        ? _fallbackCompetitorValues
        : [
            for (final key in _pillarOrder)
              graph.competitorValueFor(key)?.toDouble(),
          ];
    final competitorLabel = graph == null
        ? _fallbackCompetitorLabel
        : _initials(graph.competitorName, fallback: appText.competitorInitials);
    final myPoints = graph == null
        ? _fallbackPoints
        : graph.myTotalPoints.round();
    final pointLabel = graph == null
        ? '${appText.point} : 30/40'
        : '${appText.point} : ${_formatPoints(graph.myTotalPoints)}/${_formatPoints(graph.maxTotalPoints)}';
    final progress = graph == null
        ? .86
        : (graph.completionPercentage / 100).clamp(0, 1).toDouble();
    final progressLabel = graph == null
        ? '86 %'
        : '${_formatPoints(graph.completionPercentage)} %';
    final maxY = graph == null ? 12.0 : graph.yAxisMax.toDouble();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            AmolHeader(title: appText.amolTracking),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 20.h),
                children: [
                  _PeriodTabs(
                    period: period,
                    onChanged: (value) => bloc.add(SelectPeriod(value.index)),
                  ),
                  SizedBox(height: 16.h),
                  AmolSummaryCard(
                    pointLabel: pointLabel,
                    progressLabel: progressLabel,
                    progress: progress,
                  ),
                  SizedBox(height: 14.h),
                  _DateNavigator(
                    label: formatAmolDate(state.date, appText),
                    subtitle: '${period.label(appText)} ${appText.amolTrack}',
                    onPrevious: () => bloc.add(ShiftDate(period.step, -1)),
                    onNext: () => bloc.add(ShiftDate(period.step, 1)),
                  ),
                  if (period == _AmolPeriod.monthly) ...[
                    SizedBox(height: 10.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _MonthDropdown(
                        selectedMonth: DateTime(
                          state.date.year,
                          state.date.month,
                        ),
                        months: _lastTwelveMonths(state.today),
                        appText: appText,
                        onChanged: (month) => bloc.add(SelectMonth(month)),
                      ),
                    ),
                  ],
                  SizedBox(height: 18.h),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: appText.todays,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15.sp,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Times New Roman',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' ${appText.averageTodaysDays}',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  const _Legend(),
                  SizedBox(height: 10.h),
                  _AmolLineChart(
                    categories: categories,
                    values: values,
                    competitorValues: competitorValues,
                    competitorLabel: competitorLabel,
                    maxY: maxY,
                  ),
                  SizedBox(height: 18.h),
                  _MyPointsBar(points: myPoints),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.period, required this.onChanged});

  final _AmolPeriod period;
  final ValueChanged<_AmolPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4EA),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        children: [
          for (final value in _AmolPeriod.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(vertical: 9.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == period
                        ? const Color(0xFFCBD79A)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    value.label(appText),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: value == period
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: value == period
                          ? const Color(0xFF3F4A32)
                          : const Color(0xFF9AA48A),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.label,
    required this.subtitle,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final String subtitle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFDCE9B8)),
      ),
      child: Row(
        children: [
          _NavArrow(icon: Icons.chevron_left, onTap: onPrevious),
          Expanded(
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13.sp, color: Colors.black),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10.sp, color: Colors.black54),
                ),
              ],
            ),
          ),
          _NavArrow(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

/// Lets the user jump the monthly tab straight to one of the last 12
/// calendar months (e.g. "August 2026"), instead of stepping 30 days at a
/// time via [_DateNavigator]'s arrows.
class _MonthDropdown extends StatelessWidget {
  const _MonthDropdown({
    required this.selectedMonth,
    required this.months,
    required this.appText,
    required this.onChanged,
  });

  final DateTime selectedMonth;
  final List<DateTime> months;
  final AppText appText;
  final ValueChanged<DateTime> onChanged;

  String _label(DateTime month) =>
      '${appText.monthNames[month.month - 1]} ${month.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFDCE9B8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateTime>(
          // Falls back to a hint (rather than asserting) when the current
          // selection isn't one of the last 12 months, e.g. after stepping
          // further back with the date-navigator arrows.
          value: months.contains(selectedMonth) ? selectedMonth : null,
          hint: Text(
            _label(selectedMonth),
            style: TextStyle(fontSize: 13.sp, color: Colors.black),
          ),
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFF7E8C61),
            size: 18.sp,
          ),
          borderRadius: BorderRadius.circular(16.r),
          dropdownColor: Colors.white,
          style: TextStyle(fontSize: 13.sp, color: Colors.black),
          items: [
            for (final month in months)
              DropdownMenuItem(value: month, child: Text(_label(month))),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 32.r,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDCE9B8)),
        ),
        icon: Icon(icon, size: 16.sp, color: const Color(0xFF7E8C61)),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Row(
      children: [
        _LegendDot(
          color: _LineChartPainter.lineColor,
          label: appText.myPosition,
        ),
        SizedBox(width: 18.w),
        _LegendDot(
          color: _CompetitorBubble.dotColor,
          label: appText.myNearestOrCompetitor,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9.r,
          height: 9.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.black87),
        ),
      ],
    );
  }
}

class _AmolLineChart extends StatelessWidget {
  const _AmolLineChart({
    required this.categories,
    required this.values,
    required this.competitorValues,
    required this.competitorLabel,
    required this.maxY,
  });

  final List<String> categories;
  final List<double> values;

  /// The nearest competitor's score per category, `null` where the server
  /// has none for that pillar (no bubble is drawn there).
  final List<double?> competitorValues;
  final String competitorLabel;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    final height = 240.h;
    final plotLeft = 24.w;
    final plotTop = 30.h;
    final plotBottom = 48.h;
    final plotRight = 6.w;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final plotRect = Rect.fromLTWH(
          plotLeft,
          plotTop,
          (width - plotLeft - plotRight).clamp(0.0, double.infinity),
          (height - plotTop - plotBottom).clamp(0.0, double.infinity),
        );
        final points = _computePoints(plotRect, values, maxY)
            .cast<Offset>();
        final competitorPoints = _computePoints(
          plotRect,
          competitorValues,
          maxY,
        );
        return SizedBox(
          height: height,
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _LineChartPainter(
                  plotRect: plotRect,
                  categories: categories,
                  points: points,
                  maxY: maxY,
                ),
              ),
              for (final point in competitorPoints)
                if (point != null)
                  Positioned(
                    left: point.dx,
                    top: (point.dy - 32.h).clamp(0.0, height),
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: _CompetitorBubble(label: competitorLabel),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  /// Maps [values] onto [rect] using [maxY] as the y-axis ceiling. A `null`
  /// entry (only possible for competitor values) stays `null` in the
  /// result, so its bubble is skipped.
  static List<Offset?> _computePoints(
    Rect rect,
    List<double?> values,
    double maxY,
  ) {
    final stepX = values.length > 1 ? rect.width / (values.length - 1) : 0.0;
    return [
      for (var i = 0; i < values.length; i++)
        if (values[i] == null)
          null
        else
          Offset(
            rect.left + stepX * i,
            rect.bottom - (values[i]! / maxY).clamp(0.0, 1.0) * rect.height,
          ),
    ];
  }
}

class _CompetitorBubble extends StatelessWidget {
  const _CompetitorBubble({required this.label});

  final String label;

  static const dotColor = Color(0xFFB9C776);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22.r,
      padding: EdgeInsets.symmetric(horizontal: 7.w),
      decoration: BoxDecoration(
        color: dotColor.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.r,
            height: 5.r,
            decoration: const BoxDecoration(
              color: Color(0xFF3F4A32),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3F4A32),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.plotRect,
    required this.categories,
    required this.points,
    required this.maxY,
  });

  final Rect plotRect;
  final List<String> categories;
  final List<Offset> points;
  final double maxY;

  static const lineColor = Color(0xFF5D8067);
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
        (maxY * i / _ySteps).round().toString(),
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

    for (var i = 0; i < categories.length; i++) {
      final x = i < points.length ? points[i].dx : plotRect.left;
      canvas.save();
      canvas.translate(x, plotRect.bottom + 10.h);
      canvas.rotate(-0.6);
      _paintLabel(canvas, categories[i], Offset.zero, alignRight: true);
      canvas.restore();
    }
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    Offset anchor, {
    bool alignRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 9.sp, color: _labelColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = alignRight
        ? Offset(anchor.dx - painter.width, anchor.dy - painter.height / 2)
        : anchor;
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.plotRect != plotRect;
}

class _MyPointsBar extends StatelessWidget {
  const _MyPointsBar({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: const ShapeDecoration(
        color: Color(0xFFDCE7AC),
        shape: StadiumBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                '${AppText.of(context).myPoints} : $points',
                style: TextStyle(fontSize: 13.sp, color: Colors.black),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                decoration: const BoxDecoration(
                  color: Color(0xFF5D8067),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 5.w),
              Text(
                '$points',
                style: TextStyle(fontSize: 12.sp, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
