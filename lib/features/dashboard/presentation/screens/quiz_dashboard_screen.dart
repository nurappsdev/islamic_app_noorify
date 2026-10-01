import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/app_route_observer.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/dashboard/presentation/bloc/quiz_dashboard_bloc.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/bloc/quiz_bloc.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_failure_message.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_formatters.dart';
// import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_activity_chart.dart';
// import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_comparison_card.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_segmented_tabs.dart';
// import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_stat_grid.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_attempt_card.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_status_view.dart';

/// Performance dashboard opened from the final item in the Quiz navigation.
/// Reads the [QuizDashboardBloc] (`/quizzes/dashboard` and
/// `/quizzes/dashboard/compare`) and the [QuizBloc] history preview provided
/// above it.
class QuizDashboardScreen extends StatefulWidget {
  const QuizDashboardScreen({super.key});

  @override
  State<QuizDashboardScreen> createState() => _QuizDashboardScreenState();
}

class _QuizDashboardScreenState extends State<QuizDashboardScreen>
    with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// The Quiz section keeps this tab alive, so it refreshes whenever a page
  /// above it (a quiz, its result) closes - a new attempt shows up at once.
  @override
  void didPopNext() {
    context.read<QuizDashboardBloc>().add(const LoadQuizDashboard());
    context.read<QuizBloc>().add(const LoadCompletedQuizHistory());
  }

  @override
  Widget build(BuildContext context) => const _QuizDashboardView();
}

class _QuizDashboardView extends StatelessWidget {
  const _QuizDashboardView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuizDashboardBloc>().state;
    final bloc = context.read<QuizDashboardBloc>();
    final appText = AppText.of(context);
    final comparison = state.comparison;
    // The current user and the other, by the server's `isCurrentUser`.
    final me = comparison?.currentUser;
    final other = comparison?.otherUser;
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 88.h),
              children: [
                _DashboardHeader(onBack: () => Navigator.maybePop(context)),
                SizedBox(height: 10.h),
                QuizSegmentedTabs(
                  labels: [appText.daily, appText.weekly, appText.monthly],
                  selectedIndex: state.selectedPeriod,
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
                        text:
                            '${[appText.todays, appText.weekly, appText.monthly][state.selectedPeriod]} - ',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 22.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(
                        text: context.localizedDigits(
                          '${appText.averageScore} : ${formatOptional(state.dashboard?.totals.averageScorePercentage, formatPercent)}',
                        ),
                      ),
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
                      _ScoreDonut(
                        mine: me?.dashboard.totals.totalPoints,
                        theirs: other?.dashboard.totals.totalPoints,
                      ),
                      if (state.comparisonStatus ==
                          QuizDashboardLoadStatus.loading)
                        const CircularProgressIndicator(),
                      if (state.showCompetitor && other != null)
                        Positioned(
                          top: 11.h,
                          right: 6.w,
                          child: _CompetitorCard(
                            competitor: other,
                            onClose: () => bloc.add(const DismissCompetitor()),
                          ),
                        ),
                    ],
                  ),
                ),
                if (state.comparisonStatus == QuizDashboardLoadStatus.failure)
                  QuizStatusView(
                    message: quizFailureMessage(
                      appText,
                      state.comparisonFailure,
                    ),
                    onRetry: () => bloc.add(const LoadQuizDashboard()),
                  )
                else
                  _PointsSummary(
                    mine: me?.dashboard.totals.totalPoints,
                    theirs: other?.dashboard.totals.totalPoints,
                  ),
                // Comparison card - hidden for now; uncomment to show it.
                // if (comparison != null) ...[
                //   SizedBox(height: 16.h),
                //   QuizComparisonCard(comparison: comparison),
                // ],
                // Stats card (attempts, questions, correct / incorrect /
                // unanswered, accuracy, correct rate, points, total time,
                // current streak, avg. min / day, best and average score) -
                // hidden for now; uncomment it and its class below to show it.
                // SizedBox(height: 20.h),
                // const _DashboardFigures(),
                SizedBox(height: 25.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        appText.quizHistory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(RouteNames.completedHistory),
                      style: TextButton.styleFrom(
                        foregroundColor: context.inkColor(Colors.black),
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
                const _HistoryPreview(),
              ],
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
              color: context.inkColor(Color(0xFF84945F)),
              fontSize: 20.sp,
              fontWeight: FontWeight.w400,
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
        border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
        borderRadius: BorderRadius.circular(26.r),
      ),
      child: Row(
        children: [
          _DateArrow(icon: Icons.arrow_back_rounded, onTap: onPrevious),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // One line each, so a long Bangla label cannot outgrow the box.
                Text(
                  _label(appText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(height: 8.h),
                Text(
                  _subLabel(appText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.sp),
                ),
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
          decoration: BoxDecoration(
            color: context.surfaceColor(color),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 10.w),
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: context.inkColor(color), fontSize: 14.sp),
          ),
        ),
      ],
    );
  }
}

/// The two users' points over the range, each an arc sized by its share.
class _ScoreDonut extends StatelessWidget {
  const _ScoreDonut({required this.mine, required this.theirs});

  final num? mine;
  final num? theirs;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(245.w, 245.w),
      painter: _ScoreDonutPainter(
        mine: (mine ?? 0).toDouble(),
        theirs: (theirs ?? 0).toDouble(),
        track: context.surfaceColor(const Color(0xFFF0F0F6)),
      ),
    );
  }
}

class _ScoreDonutPainter extends CustomPainter {
  _ScoreDonutPainter({
    required this.mine,
    required this.theirs,
    required this.track,
  });

  final double mine;
  final double theirs;
  final Color track;

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
    final total = mine + theirs;
    if (total <= 0) {
      // Nothing earned by either yet: an empty ring.
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * .18,
      );
      return;
    }
    // A small gap between the arcs, as in the design, when both have points.
    const gap = math.pi * .12;
    final both = mine > 0 && theirs > 0;
    final available = math.pi * 2 - (both ? gap * 2 : 0);
    final mineSweep = available * mine / total;
    const start = math.pi * .82;
    if (mine > 0) canvas.drawArc(rect, start, mineSweep, false, green);
    if (theirs > 0) {
      canvas.drawArc(
        rect,
        start + mineSweep + (both ? gap : 0),
        available - mineSweep,
        false,
        olive,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreDonutPainter oldDelegate) =>
      oldDelegate.mine != mine ||
      oldDelegate.theirs != theirs ||
      oldDelegate.track != track;
}

class _CompetitorCard extends StatelessWidget {
  const _CompetitorCard({required this.competitor, required this.onClose});

  final QuizComparedUser competitor;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Sized by its content, so the points sit right under the name.
      width: 164.w,
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 6.w, 12.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFDDE8BA)),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.lineColor(Color(0xFFF5F5F5))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    competitor.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.inkColor(const Color(0xFF303629)),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              // Inside the card, beside the name, so nothing clips it.
              IconButton(
                onPressed: onClose,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 28.r, height: 28.r),
                style: IconButton.styleFrom(
                  backgroundColor: context.surfaceColor(Colors.white),
                  shape: const CircleBorder(),
                ),
                icon: Icon(
                  Icons.close_rounded,
                  color: const Color(0xFFE53935),
                  size: 18.r,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            context.localizedDigits(
              '${AppText.of(context).point} : '
              '${formatPoints(competitor.dashboard.totals.totalPoints)}',
            ),
            style: TextStyle(
              color: context.inkColor(const Color(0xFF5D896D)),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Both users' points over the range; `—` until they have loaded.
class _PointsSummary extends StatelessWidget {
  const _PointsSummary({required this.mine, required this.theirs});

  final num? mine;
  final num? theirs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51.h,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFF3F5E4)),
        borderRadius: BorderRadius.circular(26.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.surfaceColor(Color(0xFFDDE8BA)),
                borderRadius: BorderRadius.circular(26.r),
              ),
              child: Text(
                context.localizedDigits(
                  '${AppText.of(context).myPoints} : '
                  '${formatOptional(mine, formatPoints)}',
                ),
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
                Text(
                  context.localizedDigits(formatOptional(theirs, formatPoints)),
                  style: TextStyle(fontSize: 16.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The latest attempts, as returned by `GET /quizzes/attempts`.
class _HistoryPreview extends StatelessWidget {
  const _HistoryPreview();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<QuizBloc>().state;
    switch (state.status) {
      case QuizStatus.initial:
      case QuizStatus.loading:
        return Padding(
          padding: EdgeInsets.all(16.h),
          child: const Center(child: CircularProgressIndicator()),
        );
      case QuizStatus.failure:
        return QuizStatusView(
          message: quizFailureMessage(appText, state.failure),
          onRetry: () =>
              context.read<QuizBloc>().add(const LoadCompletedQuizHistory()),
        );
      case QuizStatus.success:
        if (state.attempts.isEmpty) {
          return QuizStatusView(message: appText.noQuizAttemptsYet);
        }
        return Column(
          children: [
            for (final attempt in state.attempts) ...[
              QuizAttemptCard(attempt: attempt),
              SizedBox(height: 8.h),
            ],
          ],
        );
    }
  }
}

// Stats card - hidden for now; see its use in the build above.
// /// The range's figures from `GET /quizzes/dashboard`, and its days as a chart.
// class _DashboardFigures extends StatelessWidget {
//   const _DashboardFigures();
//
//   @override
//   Widget build(BuildContext context) {
//     final appText = AppText.of(context);
//     final state = context.watch<QuizDashboardBloc>().state;
//     final dashboard = state.dashboard;
//     switch (state.dashboardStatus) {
//       case QuizDashboardLoadStatus.initial:
//       case QuizDashboardLoadStatus.loading:
//         return Padding(
//           padding: EdgeInsets.all(24.h),
//           child: const Center(child: CircularProgressIndicator()),
//         );
//       case QuizDashboardLoadStatus.failure:
//         return QuizStatusView(
//           message: quizFailureMessage(appText, state.dashboardFailure),
//           onRetry: () =>
//               context.read<QuizDashboardBloc>().add(const LoadQuizDashboard()),
//         );
//       case QuizDashboardLoadStatus.success:
//         if (dashboard == null) return const SizedBox.shrink();
//         final t = dashboard.totals;
//         String count(int? value) => value == null ? '—' : '$value';
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: EdgeInsets.all(14.w),
//               decoration: BoxDecoration(
//                 color: context.surfaceColor(Color(0xFFDFE9B9)),
//                 borderRadius: BorderRadius.circular(18.r),
//               ),
//               child: QuizStatGrid(
//                 stats: [
//                   (appText.attemptsLabel, '${t.attempts}'),
//                   (appText.questionsWord, '${t.totalQuestions}'),
//                   (appText.correctAnswers, '${t.correctAnswers}'),
//                   (appText.incorrectAnswers, count(t.wrongAnswers)),
//                   (appText.unansweredLabel, count(t.unansweredQuestions)),
//                   (
//                     appText.accuracy,
//                     formatOptional(t.accuracyPercentage, formatPercent),
//                   ),
//                   (
//                     appText.correctPercentageLabel,
//                     formatPercent(t.correctPercentage),
//                   ),
//                   (appText.pointsWord, formatPoints(t.totalPoints)),
//                   (appText.totalTimeLabel, formatClock(t.totalSeconds)),
//                   (
//                     appText.currentStreakLabel,
//                     '${t.currentStreak} ${appText.daysWord}',
//                   ),
//                   (
//                     appText.averageMinutesPerDayLabel,
//                     formatPoints(t.averageMinutesPerDay),
//                   ),
//                   (appText.bestScore, formatPercent(t.bestScorePercentage)),
//                   (
//                     appText.averageScore,
//                     formatPercent(t.averageScorePercentage),
//                   ),
//                 ],
//               ),
//             ),
//             // Daily activity chart - hidden for now; uncomment to show it.
//             // SizedBox(height: 20.h),
//             // QuizActivityChart(days: dashboard.days),
//           ],
//         );
//     }
//   }
// }
