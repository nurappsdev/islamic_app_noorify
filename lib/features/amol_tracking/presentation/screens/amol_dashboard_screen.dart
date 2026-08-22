import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/amol_tracking/presentation/cubit/amol_dashboard_cubit.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/widgets/amol_shared_widgets.dart';

enum _AmolPeriod { daily, weekly, monthly }

extension on _AmolPeriod {
  String get label => switch (this) {
    _AmolPeriod.daily => 'Daily',
    _AmolPeriod.weekly => 'Weekly',
    _AmolPeriod.monthly => 'Monthly',
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
      create: (_) => AmolDashboardCubit(now: now),
      child: const _AmolDashboardView(),
    );
  }
}

class _AmolDashboardView extends StatelessWidget {
  const _AmolDashboardView();

  static const _categories = [
    'Fardh Prayer',
    'Sunnah and Witr',
    'Quran',
    'Nafl Salat',
    'Hadith',
    'Quiz',
    'Nafl & more',
  ];
  static const _myPosition = [6.0, 10.0, 2.0, 9.0, 2.0, 10.0, 3.0];
  static const _competitorIndices = [0, 1, 3, 5];
  static const _myPoints = 27;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AmolDashboardCubit>().state;
    final period = _AmolPeriod.values[state.selectedPeriod];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AmolHeader(title: 'Amol Tracking'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 20.h),
                children: [
                  _PeriodTabs(
                    period: period,
                    onChanged: (value) => context
                        .read<AmolDashboardCubit>()
                        .selectPeriod(value.index),
                  ),
                  SizedBox(height: 16.h),
                  const AmolSummaryCard(
                    pointLabel: 'Point : 30/40',
                    progressLabel: '86 %',
                    progress: .86,
                  ),
                  SizedBox(height: 14.h),
                  _DateNavigator(
                    label: formatAmolDate(state.date),
                    subtitle: '${period.label} Amol Track',
                    onPrevious: () => context
                        .read<AmolDashboardCubit>()
                        .shiftDate(period.step, -1),
                    onNext: () => context.read<AmolDashboardCubit>().shiftDate(
                      period.step,
                      1,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Todays',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15.sp,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Times New Roman',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' –  average todays days.',
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
                    categories: _categories,
                    values: _myPosition,
                    competitorIndices: _competitorIndices,
                    competitorLabel: 'Ab',
                    maxY: 12,
                  ),
                  SizedBox(height: 18.h),
                  const _MyPointsBar(points: _myPoints),
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
                    value.label,
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
    return Row(
      children: [
        _LegendDot(color: _LineChartPainter.lineColor, label: 'My Position'),
        SizedBox(width: 18.w),
        _LegendDot(
          color: _CompetitorBubble.dotColor,
          label: 'My Nearest Or Competitor',
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
    required this.competitorIndices,
    required this.competitorLabel,
    required this.maxY,
  });

  final List<String> categories;
  final List<double> values;
  final List<int> competitorIndices;
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
        final points = _computePoints(plotRect, values, maxY);
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
              for (final index in competitorIndices)
                Positioned(
                  left: points[index].dx,
                  top: (points[index].dy - 32.h).clamp(0.0, height),
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

  static List<Offset> _computePoints(
    Rect rect,
    List<double> values,
    double maxY,
  ) {
    final stepX = values.length > 1 ? rect.width / (values.length - 1) : 0.0;
    return [
      for (var i = 0; i < values.length; i++)
        Offset(
          rect.left + stepX * i,
          rect.bottom - (values[i] / maxY).clamp(0.0, 1.0) * rect.height,
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
                'My points : $points',
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
