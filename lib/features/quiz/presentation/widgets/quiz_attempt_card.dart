import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_formatters.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_navigation.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_category_card.dart';

/// One finished attempt in the quiz history, with its server-computed score.
/// Tapping it opens the answer review.
class QuizAttemptCard extends StatelessWidget {
  const QuizAttemptCard({
    super.key,
    required this.attempt,
    this.showDate = false,
  });

  final QuizAttempt attempt;

  /// Adds the day the attempt was completed to its title, so the daily
  /// quizzes in a long history can be told apart.
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final categoryName = context.localized(attempt.category?.name);
    final name = attempt.attemptType == QuizAttemptType.daily
        ? appText.dailyQuiz
        : (categoryName.isEmpty ? appText.categoryQuiz : categoryName);
    final completedAt = attempt.completedAt;
    final title = showDate && completedAt != null
        ? context.localizedDigits(
            '$name - ${formatQuizDay(completedAt, appText.monthNames)}',
          )
        : name;
    return InkWell(
      onTap: attempt.id.isEmpty
          ? null
          : () => openQuizAttemptReview(context, attempt.id),
      borderRadius: BorderRadius.circular(25.r),
      child: Container(
        height: 80.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
              ),
              child: QuizCategoryIcon(
                iconUrl: attempt.category?.iconUrl,
                fallback: Icons.image_outlined,
                size: 24.sp,
                color: context.inkColor(Color(0xFF8B9865)),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: showDate ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    context.localizedDigits(
                      '${attempt.totalQuestions} ${appText.questionsWord}',
                    ),
                    style: TextStyle(
                      color: const Color(0xFFA1AD59),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            QuizScoreRing(scorePercentage: attempt.scorePercentage),
          ],
        ),
      ),
    );
  }
}

/// The server's score percentage as a ring.
class QuizScoreRing extends StatelessWidget {
  const QuizScoreRing({super.key, required this.scorePercentage});

  final num scorePercentage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 57.w,
      height: 57.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (scorePercentage / 100).clamp(0, 1).toDouble(),
            strokeWidth: 5.w,
            strokeCap: StrokeCap.round,
            color: const Color(0xFFA1AD59),
            backgroundColor: context.surfaceColor(Color(0xFFF0F0F6)),
          ),
          Text(
            context.localizedDigits(formatPercent(scorePercentage)),
            style: TextStyle(color: const Color(0xFFA1AD59), fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
