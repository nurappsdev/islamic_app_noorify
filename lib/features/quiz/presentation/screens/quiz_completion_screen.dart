import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_enums.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_formatters.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_navigation.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_route_args.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/screens/quiz_categories_screen.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_bottom_nav.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_stat_grid.dart';

/// The server-scored result of a submitted quiz. Every figure is shown as the
/// API returned it. Expects a `QuizCategoriesBloc` above it.
class QuizCompletionScreen extends StatelessWidget {
  const QuizCompletionScreen({super.key, required this.args});

  final QuizCompletionArgs? args;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final result = args?.result;
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(bottom: 90.h),
              children: [
                _CompletionHero(
                  result: result,
                  onBack: () => Navigator.maybePop(context),
                ),
                if (result != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(13.w, 18.h, 13.w, 0),
                    child: _ResultSummary(result: result),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(22.w, 23.h, 22.w, 14.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        appText.categories,
                        style: TextStyle(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(RouteNames.quizList),
                        child: Text(
                          appText.seeAll,
                          style: TextStyle(
                            color: context.inkColor(Colors.black),
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const QuizCategoryPreview(count: 2),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: QuizBottomNav(selectedIndex: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionHero extends StatelessWidget {
  const _CompletionHero({required this.result, required this.onBack});
  final QuizAttemptResult? result;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final isDaily = result?.attemptType == QuizAttemptType.daily;
    // Today's quiz points as the amol record now holds them (the best of the
    // day), falling back to this attempt's points.
    final todaysPoints = result?.amol?.quizPoints ?? result?.pointsEarned;
    return Container(
      height: 246.h,
      padding: EdgeInsets.fromLTRB(19.w, 16.h, 24.w, 28.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFE4ECC5)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(37.r),
          bottomRight: Radius.circular(37.r),
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: onBack,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFDFDE68),
                foregroundColor: Color(0xFF303629),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            ),
          ),
          Positioned(
            left: 20.w,
            bottom: 23.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDaily || result == null
                      ? appText.youCompletedTodaysChallenge
                      : appText.youCompletedTheQuiz,
                  style: TextStyle(
                    color: AppColor.primary,
                    fontSize: 22.sp,
                    height: 1.28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isDaily && todaysPoints != null) ...[
                  SizedBox(height: 28.h),
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: context.inkColor(Color(0xFF31555D)),
                        size: 31,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        context.localizedDigits(
                          '${appText.todaysPointsLabel} : '
                          '${formatPoints(todaysPoints)}',
                        ),
                        style: TextStyle(
                          color: AppColor.primary,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Positioned(right: 0, bottom: 6.h, child: const _SuccessMark()),
        ],
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 143.w,
    height: 132.w,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -.18,
          child: Container(
            width: 106.w,
            height: 106.w,
            decoration: BoxDecoration(
              color: context.surfaceColor(Color(0xFFF5F5F4)),
              borderRadius: BorderRadius.circular(35.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .12),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
        ),
        Icon(
          Icons.check_rounded,
          color: context.inkColor(Color(0xFF82D020)),
          size: 87.sp,
          shadows: [
            Shadow(
              color: const Color(0xFF4B8A11).withValues(alpha: .6),
              offset: const Offset(2, 4),
              blurRadius: 2,
            ),
          ],
        ),
      ],
    ),
  );
}

/// The attempt's figures exactly as the server scored them.
class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.result});

  final QuizAttemptResult result;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    // Category practice earns no amol points, so its points are not shown.
    final showPoints = result.attemptType == QuizAttemptType.daily;
    final stats = <QuizStat>[
      (appText.questionsWord, '${result.totalQuestions}'),
      (appText.correctAnswers, '${result.correctAnswers}'),
      (appText.incorrectAnswers, '${result.incorrectAnswers}'),
      (appText.scoreLabel, formatPercent(result.scorePercentage)),
      if (showPoints)
        (
          appText.pointsWord,
          '${formatPoints(result.pointsEarned)} / '
              '${formatPoints(result.maxPoints)}',
        ),
      (appText.timeSpent, formatClock(result.timeSpentSeconds)),
    ];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFDFE9B9)),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        children: [
          QuizStatGrid(stats: stats),
          if (result.id.isNotEmpty) ...[
            SizedBox(height: 14.h),
            FilledButton(
              onPressed: () => openQuizAttemptReview(context, result.id),
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.primary,
                minimumSize: Size(double.infinity, 40.h),
              ),
              child: Text(
                appText.reviewAnswers,
                style: TextStyle(fontSize: 12.sp),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
