import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/dashboard/presentation/bloc/quiz_dashboard_bloc.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_bottom_nav.dart';

/// Performance dashboard opened from the final item in the Quiz navigation.
class QuizDashboardScreen extends StatelessWidget {
  const QuizDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuizDashboardBloc(),
      child: const _QuizDashboardView(),
    );
  }
}

class _QuizDashboardView extends StatelessWidget {
  const _QuizDashboardView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuizDashboardBloc>().state;
    final bloc = context.read<QuizDashboardBloc>();
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 88.h),
              children: [
                _DashboardHeader(onBack: () => Navigator.maybePop(context)),
                SizedBox(height: 10.h),
                _PeriodTabs(
                  selectedPeriod: state.selectedPeriod,
                  onChanged: (period) => bloc.add(SelectPeriod(period)),
                ),
                SizedBox(height: 13.h),
                _DateSelector(
                  selectedPeriod: state.selectedPeriod,
                  selectedDate: state.selectedDate,
                  onPrevious: () => bloc.add(const GoToPreviousDate()),
                  onNext: () => bloc.add(const GoToNextDate()),
                ),
                SizedBox(height: 20.h),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(
                      context,
                    ).style.copyWith(color: Colors.black, fontSize: 16.sp),
                    children: [
                      TextSpan(
                        text: '${appText.todays} - ',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 22.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(text: appText.averageValue),
                    ],
                  ),
                ),
                SizedBox(height: 25.h),
                const _DashboardLegend(),
                SizedBox(height: 4.h),
                SizedBox(
                  height: 293.h,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const _ScoreDonut(),
                      if (state.showCompetitor)
                        Positioned(
                          top: 11.h,
                          right: 6.w,
                          child: _CompetitorCard(
                            onClose: () => bloc.add(const DismissCompetitor()),
                          ),
                        ),
                    ],
                  ),
                ),
                const _PointsSummary(),
                SizedBox(height: 25.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appText.quizHistory,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(RouteNames.completedHistory),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        appText.seeAll,
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 25.h),
                for (var index = 1; index <= 5; index++) ...[
                  _HistoryCard(index: index),
                  SizedBox(height: 8.h),
                ],
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: QuizBottomNav(selectedIndex: 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 63.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Positioned(
          //   left: 3.w,
          //   top: 6.h,
          //   child: IconButton(
          //     onPressed: onBack,
          //     style: IconButton.styleFrom(
          //       backgroundColor: const Color(0xFFDFDE68),
          //       foregroundColor: const Color(0xFF303629),
          //       minimumSize: Size(33.w, 33.w),
          //       padding: EdgeInsets.zero,
          //     ),
          //     icon: Icon(Icons.arrow_back_ios_new_rounded, size: 15.sp),
          //   ),
          // ),
          Text(
            AppText.of(context).dashboard,
            style: TextStyle(
              color: const Color(0xFF84945F),
              fontSize: 20.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.selectedPeriod, required this.onChanged});

  final int selectedPeriod;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final labels = [appText.daily, appText.weekly, appText.monthly];
    return SizedBox(
      height: 44.h,
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(13.r),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selectedPeriod == index
                        ? const Color(0xFFDDE8BA)
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: selectedPeriod == index
                            ? Colors.transparent
                            : const Color(0xFFDDE8C1),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
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

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.selectedPeriod,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
  });

  final int selectedPeriod;
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  String _label(AppText appText) {
    final monthNames = appText.monthNames;
    switch (selectedPeriod) {
      case 1: // Weekly
        final startOfWeek = selectedDate.subtract(
          Duration(days: selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final sameMonth = startOfWeek.month == endOfWeek.month;
        final startLabel = sameMonth
            ? '${startOfWeek.day}'
            : '${startOfWeek.day} ${monthNames[startOfWeek.month - 1]}';
        return '$startLabel - ${endOfWeek.day} '
            '${monthNames[endOfWeek.month - 1]}, ${endOfWeek.year}';
      case 2: // Monthly
        return '${monthNames[selectedDate.month - 1]}, ${selectedDate.year}';
      default: // Daily
        return '${appText.weekdayNames[selectedDate.weekday - 1]} '
            '${selectedDate.day} ${monthNames[selectedDate.month - 1]}, '
            '${selectedDate.year}';
    }
  }

  String _subLabel(AppText appText) {
    switch (selectedPeriod) {
      case 1:
        return appText.weeklyQuizValue;
      case 2:
        return appText.monthlyQuizValue;
      default:
        return appText.dailyQuizValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      height: 84.h,
      padding: EdgeInsets.symmetric(horizontal: 11.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDE8C1)),
        borderRadius: BorderRadius.circular(26.r),
      ),
      child: Row(
        children: [
          _DateArrow(icon: Icons.arrow_back_rounded, onTap: onPrevious),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_label(appText), style: TextStyle(fontSize: 16.sp)),
                SizedBox(height: 8.h),
                Text(_subLabel(appText), style: TextStyle(fontSize: 14.sp)),
              ],
            ),
          ),
          _DateArrow(icon: Icons.arrow_forward_rounded, onTap: onNext),
        ],
      ),
    );
  }
}

class _DateArrow extends StatelessWidget {
  const _DateArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.w),
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFA1AD59)),
        ),
        child: Icon(icon, color: const Color(0xFFA1AD59), size: 20.sp),
      ),
    );
  }
}

class _DashboardLegend extends StatelessWidget {
  const _DashboardLegend();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Wrap(
      spacing: 27.w,
      runSpacing: 8.h,
      children: [
        _LegendItem(color: const Color(0xFF5D896D), label: appText.myPosition),
        _LegendItem(
          color: const Color(0xFFA9B258),
          label: appText.myNearestOrCompetitor,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 19.w,
          height: 19.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 10.w),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 14.sp),
        ),
      ],
    );
  }
}

class _ScoreDonut extends StatelessWidget {
  const _ScoreDonut();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(245.w, 245.w), painter: _ScoreDonutPainter());
  }
}

class _ScoreDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * .34;
    final green = Paint()
      ..color = const Color(0xFF5D896D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .18
      ..strokeCap = StrokeCap.round;
    final olive = Paint()
      ..color = const Color(0xFFA9B258)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .18
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, math.pi * .82, math.pi * .72, false, green);
    canvas.drawArc(rect, math.pi * 1.62, math.pi * 1.17, false, olive);
  }

  @override
  bool shouldRepaint(covariant _ScoreDonutPainter oldDelegate) => false;
}

class _CompetitorCard extends StatelessWidget {
  const _CompetitorCard({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148.w,
      height: 105.h,
      padding: EdgeInsets.fromLTRB(20.w, 27.h, 15.w, 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE8BA),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFF5F5F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppText.of(context).competitorName,
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                '${AppText.of(context).point} :1.5/1.0',
                style: TextStyle(fontSize: 12.sp),
              ),
            ],
          ),
          Positioned(
            top: -20.h,
            right: -10.w,
            child: IconButton(
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.cancel_outlined,
                color: const Color(0xFFF44336),
                size: 18.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsSummary extends StatelessWidget {
  const _PointsSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51.h,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5E4),
        borderRadius: BorderRadius.circular(26.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE8BA),
                borderRadius: BorderRadius.circular(26.r),
              ),
              child: Text(
                '${AppText.of(context).myPoints} : 1.0',
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              children: [
                Container(
                  width: 9.w,
                  height: 9.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA9B258),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 7.w),
                Text('1.5', style: TextStyle(fontSize: 16.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      height: 84.h,
      padding: EdgeInsets.symmetric(horizontal: 11.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDE8C1)),
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: Row(
        children: [
          Container(
            width: 51.w,
            height: 51.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDDE8C1)),
            ),
            child: Icon(
              Icons.image_outlined,
              color: const Color(0xFF8B9865),
              size: 25.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${appText.categoryQuiz} $index ( ${appText.quranicScience} )',
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 7.h),
                Text(
                  appText.questionsCountLabel,
                  style: TextStyle(
                    color: const Color(0xFFA1AD59),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          const _ScoreProgress(value: .60),
        ],
      ),
    );
  }
}

class _ScoreProgress extends StatelessWidget {
  const _ScoreProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 57.w,
      height: 57.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 5.w,
            strokeCap: StrokeCap.round,
            color: const Color(0xFFA1AD59),
            backgroundColor: const Color(0xFFF0F0F6),
          ),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(color: const Color(0xFFA1AD59), fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
