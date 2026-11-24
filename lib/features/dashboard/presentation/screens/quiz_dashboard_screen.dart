import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/app_route_observer.dart';
import 'package:tuhfatul_muslim/core/localization/localization_context.dart';
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
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_dashboard_charts.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_segmented_tabs.dart';
// import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_stat_grid.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_attempt_card.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_status_view.dart';

/// The two series colors: the signed-in user and the reader compared against
/// them. Declared once so the legend, the donut arcs and the points summary
/// can never drift apart. Both are mid-toned, so the dark mapping keeps them
/// as they are - they read on a light and a dark background alike.
const _myColor = Color(0xFF5D896D);
const _rivalColor = Color(0xFFA9B258);

/// [_myColor] darkened, for the bar the reader has tapped - the shared charts
/// strengthen the selected layer the way the Dua palette does.
const _myColorStrong = Color(0xFF466752);

/// What the weekly and monthly bars are drawn in: this screen's own two
/// colours, so a bar matches the legend that names it ("My Position") rather
/// than the Dua dashboard's palette.
const _chartPalette = DuaChartPalette(
  mine: _myColor,
  mineStrong: _myColorStrong,
  competitor: _rivalColor,
);

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
                    style: DefaultTextStyle.of(context).style.copyWith(
                      color: context.inkColor(Colors.black),
                      fontSize: 16.sp,
                    ),
                    children: [
                      TextSpan(
                        text:
                            '${[appText.todays, appText.weekly, appText.monthly][state.selectedPeriod]} - ',
                        style: TextStyle(
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
                SizedBox(height: 293.h, child: const _PeriodChart()),
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
      case 1: // Weekly - the seven days ending on the selected day.
        final startOfWeek = selectedDate.subtract(const Duration(days: 6));
        final endOfWeek = selectedDate;
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
          border: Border.all(color: context.lineColor(const Color(0xFFA1AD59))),
        ),
        child: Icon(
          icon,
          color: context.inkColor(const Color(0xFFA1AD59)),
          size: 20.sp,
        ),
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
        _LegendItem(color: _myColor, label: appText.myPosition),
        _LegendItem(color: _rivalColor, label: appText.myNearestOrCompetitor),
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
        // Mapped here, not in `paint`: a painter has no BuildContext, and
        // the legend dots map the same two colors the same way.
        mineColor: context.surfaceColor(_myColor),
        theirsColor: context.surfaceColor(_rivalColor),
      ),
    );
  }
}

class _ScoreDonutPainter extends CustomPainter {
  _ScoreDonutPainter({
    required this.mine,
    required this.theirs,
    required this.track,
    required this.mineColor,
    required this.theirsColor,
  });

  final double mine;
  final double theirs;
  final Color track;
  final Color mineColor;
  final Color theirsColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * .34;
    final green = Paint()
      ..color = mineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .18
      ..strokeCap = StrokeCap.round;
    final olive = Paint()
      ..color = theirsColor
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
      oldDelegate.track != track ||
      oldDelegate.mineColor != mineColor ||
      oldDelegate.theirsColor != theirsColor;
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
                  color: context.inkColor(const Color(0xFFE53935)),
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
                  decoration: BoxDecoration(
                    color: context.surfaceColor(_rivalColor),
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

/// The window's chart: the donut for Daily, and - as on the Hadith dashboard
/// - a day-by-day bar chart for Weekly and a four-row one for Monthly.
///
/// Daily compares two totals, which a single ring says well. Weekly and
/// monthly do not: one ring hides which days the points came from, so those
/// periods use the shared bar charts instead.
class _PeriodChart extends StatelessWidget {
  const _PeriodChart();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuizDashboardBloc>().state;
    final bloc = context.read<QuizDashboardBloc>();
    final appText = AppText.of(context);
    final me = state.comparison?.currentUser;
    final other = state.comparison?.otherUser;

    if (state.period == QuizDashboardPeriod.daily) {
      return Stack(
        alignment: Alignment.center,
        children: [
          _ScoreDonut(
            mine: me?.dashboard.totals.totalPoints,
            theirs: other?.dashboard.totals.totalPoints,
          ),
          if (state.comparisonStatus == QuizDashboardLoadStatus.loading)
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
      );
    }

    if (state.comparisonStatus == QuizDashboardLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final days = _dayPoints(state);
    if (days.isEmpty) {
      return QuizStatusView(message: appText.noQuizAttemptsYet);
    }
    final myName = me?.name ?? '';
    final rivalName = other?.name ?? '';
    return state.period == QuizDashboardPeriod.weekly
        ? _WeeklyPointsChart(
            days: days,
            appText: appText,
            myName: myName,
            rivalName: rivalName,
          )
        : _MonthlyPointsChart(
            days: days,
            appText: appText,
            myName: myName,
            rivalName: rivalName,
          );
  }
}

/// One date of the window: both readers' points for it, and my attempts.
///
/// Unlike the Dua dashboard - which projects its competitor layer from a
/// single whole-window ratio - the quiz answer carries a real per-day figure
/// for both readers, so each bar's lighter layer is the rival's own day.
class _DayPoints {
  const _DayPoints({
    required this.date,
    required this.mine,
    required this.theirs,
    required this.attempts,
  });

  final DateTime date;
  final double mine;
  final double? theirs;
  final int attempts;
}

/// `YYYY-MM-DD`, so a date matches whichever way the server spelled its own.
String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

Map<String, QuizDashboardDayMetric> _byDate(
  List<QuizDashboardDayMetric>? days,
) => {
  for (final day in days ?? const <QuizDashboardDayMetric>[])
    if (DateTime.tryParse(day.date) case final date?) _dateKey(date): day,
};

/// Every day of the window, in date order, with both readers' points.
///
/// Built from the window itself rather than from the answer, because the
/// server sends a day only for a reader who was active on it. Walking my own
/// days instead got both of these wrong: a quiet week drew one column rather
/// than seven, and a day the other reader scored on but I did not vanished
/// from the chart altogether.
///
/// So a day missing from a reader's answer is that reader's real zero.
/// [_DayPoints.theirs] stays null only when no comparison has loaded at all,
/// which is what tells the chart to leave the rival layer off entirely -
/// distinct from a day they genuinely scored nothing on.
List<_DayPoints> _dayPoints(QuizDashboardState state) {
  final range = quizDashboardRange(state.period, state.selectedDate);
  final mine = _byDate(
    state.comparison?.currentUser?.dashboard.days ?? state.dashboard?.days,
  );
  final rivalDays = state.comparison?.otherUser?.dashboard.days;
  final theirs = _byDate(rivalDays);
  final span = range.to.difference(range.from).inDays;
  return [
    // `DateTime(y, m, d + i)` rather than `add(Duration(days: i))`: it
    // normalizes the overflow into the next month without a daylight-saving
    // shift moving a day onto its neighbour.
    for (var i = 0; i <= span; i++)
      if (DateTime(range.from.year, range.from.month, range.from.day + i)
          case final date)
        _DayPoints(
          date: date,
          mine: mine[_dateKey(date)]?.totalPoints.toDouble() ?? 0,
          theirs: rivalDays == null
              ? null
              : theirs[_dateKey(date)]?.totalPoints.toDouble() ?? 0,
          attempts: mine[_dateKey(date)]?.attempts ?? 0,
        ),
  ];
}

/// Quiz points are fractions - 0.4, 1.2, 2.3 - and [DuaChartBar] carries
/// whole numbers, so they are scaled by this before being handed over and
/// divided back out on the axis. Rounding them straight to integers lost the
/// difference the chart exists to show: 1.2 and 1.4 both became 1, and
/// anything under half a point became an empty column.
const _pointScale = 100;

int _scaled(double points) => (points * _pointScale).round();

/// How the bar charts' axis prints a scaled tick, back in points.
String _pointAxisLabel(int tick) => formatPoints(tick / _pointScale);

/// The card a bar shows when tapped: both readers' points, my attempts under
/// mine.
Widget _chartTooltip(
  BuildContext context, {
  required AppText appText,
  required String title,
  required double mine,
  required double? theirs,
  required int attempts,
  required String myName,
  required String rivalName,
}) {
  return DuaChartTooltip(
    title: context.localizedDigits(title),
    lines: [
      DuaTooltipLine.metric(
        color: _myColor,
        text: myName.isEmpty ? appText.myPosition : myName,
        value: context.localizedDigits(formatPoints(mine)),
      ),
      DuaTooltipLine.note(
        context.localizedDigits('${appText.attemptsLabel} : $attempts'),
      ),
      if (theirs != null) ...[
        DuaTooltipLine.metric(
          color: _rivalColor,
          text: rivalName.isEmpty ? appText.myNearestOrCompetitor : rivalName,
          value: context.localizedDigits(formatPoints(theirs)),
        ),
        // The gap, signed, so a day reads as ahead or behind at a glance
        // instead of leaving the two figures to be subtracted by eye.
        DuaTooltipLine.note(
          context.localizedDigits(
            '${mine >= theirs ? '+' : '-'}'
            '${formatPoints((mine - theirs).abs())}',
          ),
        ),
      ],
    ],
  );
}

/// One column per day of the selected week, labelled with its weekday.
class _WeeklyPointsChart extends StatelessWidget {
  const _WeeklyPointsChart({
    required this.days,
    required this.appText,
    required this.myName,
    required this.rivalName,
  });

  final List<_DayPoints> days;
  final AppText appText;
  final String myName;
  final String rivalName;

  @override
  Widget build(BuildContext context) {
    return DuaWeeklyBarChart(
      palette: _chartPalette,
      axisLabel: _pointAxisLabel,
      bars: [
        for (final day in days)
          DuaChartBar(
            // Short and Sunday-first, as the bar charts' axis expects:
            // `weekday % 7` turns Sunday's 7 into 0.
            label: context.localizedDates.weekdayShort(day.date.weekday % 7),
            mine: _scaled(day.mine),
            competitor: _scaled(day.theirs ?? 0),
          ),
      ],
      tooltipBuilder: (index, bar) {
        final day = days[index];
        return _chartTooltip(
          context,
          appText: appText,
          title: bar.title,
          mine: day.mine,
          theirs: day.theirs,
          attempts: day.attempts,
          myName: myName,
          rivalName: rivalName,
        );
      },
    );
  }
}

/// The month in rows of roughly a week - `1-7`, `8-14`, `15-21` and `22-` its
/// last day - which is how the Hadith dashboard groups its own monthly view.
/// A row no day of the window falls in is left out rather than drawn empty.
class _MonthlyPointsChart extends StatelessWidget {
  const _MonthlyPointsChart({
    required this.days,
    required this.appText,
    required this.myName,
    required this.rivalName,
  });

  final List<_DayPoints> days;
  final AppText appText;
  final String myName;
  final String rivalName;

  List<_DayPoints> _rowDays(int from, int to) => [
    for (final day in days)
      if (day.date.day >= from && day.date.day <= to) day,
  ];

  List<({String label, List<_DayPoints> days})> get _rows {
    if (days.isEmpty) return const [];
    final month = days.first.date;
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    const starts = [1, 8, 15, 22];
    final rows = <({String label, List<_DayPoints> days})>[];
    for (var i = 0; i < starts.length; i++) {
      final from = starts[i];
      final to = i + 1 < starts.length ? starts[i + 1] - 1 : lastDay;
      final rowDays = _rowDays(from, to);
      if (rowDays.isNotEmpty) {
        rows.add((label: '$from-$to', days: rowDays));
      }
      // A row is skipped only when the window holds no day in it at all -
      // never because both readers scored nothing, which is a real zero now.
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    double mineOf(List<_DayPoints> d) =>
        d.fold<double>(0, (sum, day) => sum + day.mine);
    double? theirsOf(List<_DayPoints> d) => d.any((day) => day.theirs != null)
        ? d.fold<double>(0, (sum, day) => sum + (day.theirs ?? 0))
        : null;

    return DuaMonthlyBarChart(
      palette: _chartPalette,
      axisLabel: _pointAxisLabel,
      bars: [
        for (final row in rows)
          DuaChartBar(
            label: duaPeriodAxisLabel(row.label),
            title: row.label,
            mine: _scaled(mineOf(row.days)),
            competitor: _scaled(theirsOf(row.days) ?? 0),
          ),
      ],
      tooltipBuilder: (index, bar) {
        final row = rows[index];
        return _chartTooltip(
          context,
          appText: appText,
          title: bar.title,
          mine: mineOf(row.days),
          theirs: theirsOf(row.days),
          attempts: row.days.fold<int>(0, (sum, day) => sum + day.attempts),
          myName: myName,
          rivalName: rivalName,
        );
      },
    );
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
