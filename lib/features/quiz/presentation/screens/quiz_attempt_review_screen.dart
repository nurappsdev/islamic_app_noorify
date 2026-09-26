import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';
import 'package:islami_app_noorify/features/quiz/presentation/bloc/quiz_attempt_review_bloc.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_failure_message.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_formatters.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_attempt_card.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_segmented_tabs.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_stat_grid.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_status_view.dart';

const _correctColor = Color(0xFF20C664);
const _incorrectColor = Color(0xFFC90009);
const _unansweredColor = Color(0xFF9E9E9E);

/// Question-by-question review of a finished attempt
/// (`GET /quizzes/attempts/{id}/review`). How each question is marked comes
/// from the server's `status`. Expects a [QuizAttemptReviewBloc].
class QuizAttemptReviewScreen extends StatefulWidget {
  const QuizAttemptReviewScreen({super.key});

  @override
  State<QuizAttemptReviewScreen> createState() =>
      _QuizAttemptReviewScreenState();
}

class _QuizAttemptReviewScreenState extends State<QuizAttemptReviewScreen> {
  /// All, then the server's correct / incorrect / unanswered groups.
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 0),
          child: Column(
            children: [
              _ReviewHeader(onBack: () => Navigator.maybePop(context)),
              SizedBox(height: 12.h),
              Expanded(
                child:
                    BlocBuilder<QuizAttemptReviewBloc, QuizAttemptReviewState>(
                      builder: (context, state) {
                        final detail = state.detail;
                        switch (state.status) {
                          case QuizAttemptReviewStatus.loading:
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          case QuizAttemptReviewStatus.failure:
                            return QuizStatusView(
                              message: quizFailureMessage(
                                appText,
                                state.failure,
                                forAttempt: true,
                              ),
                              // A missing attempt will not appear on retry.
                              onRetry: state.failure?.statusCode == 404
                                  ? null
                                  : () => context
                                        .read<QuizAttemptReviewBloc>()
                                        .add(const LoadQuizAttemptReview()),
                            );
                          case QuizAttemptReviewStatus.success:
                            if (detail == null) {
                              return QuizStatusView(
                                message: appText.quizErrorGeneric,
                              );
                            }
                            return _ReviewBody(
                              detail: detail,
                              tab: _tab,
                              onTabChanged: (tab) => setState(() => _tab = tab),
                            );
                        }
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.detail,
    required this.tab,
    required this.onTabChanged,
  });

  final QuizAttemptDetail detail;
  final int tab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final review = detail.review;
    // The ordered list for All; the server's own groups for the rest.
    final groups = [
      detail.questions,
      review.correct,
      review.incorrect,
      review.unanswered,
    ];
    final labels = [
      appText.allLabel,
      appText.correctLabel,
      appText.incorrectLabel,
      appText.unansweredLabel,
    ];
    final questions = groups[tab];
    // Numbered by the place each question had in the attempt.
    final numberOf = {
      for (var i = 0; i < detail.questions.length; i++)
        detail.questions[i].id: i + 1,
    };

    return ListView(
      padding: EdgeInsets.only(bottom: 24.h),
      children: [
        _AttemptOverview(detail: detail),
        SizedBox(height: 12.h),
        QuizSegmentedTabs(
          fontSize: 11.sp,
          selectedIndex: tab,
          onChanged: onTabChanged,
          labels: [
            for (var i = 0; i < labels.length; i++)
              context.localizedDigits('${labels[i]} (${groups[i].length})'),
          ],
        ),
        SizedBox(height: 10.h),
        if (questions.isEmpty)
          QuizStatusView(message: appText.noQuestionsInGroup)
        else
          for (final question in questions) ...[
            _EvaluatedQuestionCard(
              number: numberOf[question.id] ?? 0,
              question: question,
            ),
            SizedBox(height: 10.h),
          ],
      ],
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 35.h,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFDFDE68),
              foregroundColor: Color(0xFF303629),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        Text(
          AppText.of(context).reviewAnswers,
          style: TextStyle(color: AppColor.primary, fontSize: 18.sp),
        ),
      ],
    ),
  );
}

/// The attempt's figures exactly as the server sent them.
class _AttemptOverview extends StatelessWidget {
  const _AttemptOverview({required this.detail});

  final QuizAttemptDetail detail;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final attempt = detail.attempt;
    final completedAt = attempt.completedAt;
    Widget line(String label, String value, [Color? color]) => Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Text(
        context.localizedDigits('$label : $value'),
        style: TextStyle(fontSize: 12.sp, color: color),
      ),
    );
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFDFE9B9)),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              QuizScoreRing(scorePercentage: attempt.scorePercentage),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    line(appText.questionsWord, '${attempt.totalQuestions}'),
                    line(
                      appText.correctAnswers,
                      '${attempt.correctAnswers}',
                      context.inkColor(_correctColor),
                    ),
                    line(
                      appText.incorrectAnswers,
                      '${attempt.incorrectAnswers}',
                      context.inkColor(_incorrectColor),
                    ),
                    line(
                      appText.unansweredLabel,
                      formatOptional(
                        detail.unansweredQuestions,
                        (v) => '${v.toInt()}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          QuizStatGrid(
            stats: [
              (
                appText.answeredLabel,
                formatOptional(detail.answeredPercentage, formatPercent),
              ),
              (
                appText.correctPercentageLabel,
                formatPercent(detail.correctPercentage),
              ),
              (
                appText.accuracy,
                formatOptional(detail.accuracyPercentage, formatPercent),
              ),
              (appText.scoreLabel, formatPercent(attempt.scorePercentage)),
              (
                appText.pointsWord,
                '${formatPoints(attempt.pointsEarned)} / '
                    '${formatPoints(attempt.maxPoints)}',
              ),
              (appText.timeSpent, formatClock(attempt.timeSpentSeconds)),
            ],
          ),
          SizedBox(height: 10.h),
          if (completedAt != null)
            line(
              appText.completedAtLabel,
              formatQuizDateTime(completedAt, appText.monthNames),
            ),
          line(
            appText.fiftyFiftyUsedLabel,
            attempt.used5050Lifeline ? appText.yes : appText.no,
          ),
        ],
      ),
    );
  }
}

class _EvaluatedQuestionCard extends StatelessWidget {
  const _EvaluatedQuestionCard({required this.number, required this.question});

  final int number;
  final EvaluatedQuestion question;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final text = context.localized(question.question);
    final explanation = context.localized(question.explanation);
    final category = context.localized(question.category?.name);
    final difficulty = context.localized(question.difficultyLabel);
    final (statusColor, statusIcon, statusLabel) = switch (question.status) {
      QuizAnswerStatus.correct => (
        _correctColor,
        Icons.check,
        appText.correctLabel,
      ),
      QuizAnswerStatus.incorrect => (
        _incorrectColor,
        Icons.close,
        appText.incorrectLabel,
      ),
      QuizAnswerStatus.unanswered => (
        _unansweredColor,
        Icons.remove,
        appText.unansweredLabel,
      ),
    };
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  context.localizedDigits('$number. ') +
                      (text.isEmpty ? appText.questionUnavailable : text),
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              SizedBox(width: 8.w),
              Tooltip(
                message: statusLabel,
                child: CircleAvatar(
                  radius: 12.r,
                  backgroundColor: context.surfaceColor(statusColor),
                  child: Icon(statusIcon, color: Colors.white, size: 15.sp),
                ),
              ),
            ],
          ),
          if (category.isNotEmpty || difficulty.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: [
                if (category.isNotEmpty)
                  _Chip('${appText.quizCategoryLabel}: $category'),
                if (difficulty.isNotEmpty)
                  _Chip('${appText.difficultyLabel}: $difficulty'),
              ],
            ),
          ],
          SizedBox(height: 10.h),
          for (final option in question.options) ...[
            _ReviewOptionTile(
              label: option.key.toLowerCase(),
              text: context.localized(option.text),
              isCorrectAnswer: option.key == question.correctAnswerKey,
              isUserChoice: option.key == question.checkedBy,
            ),
            SizedBox(height: 5.h),
          ],
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              question.status == QuizAnswerStatus.unanswered
                  ? appText.notAnswered
                  : statusLabel,
              style: TextStyle(
                fontSize: 12.sp,
                color: context.inkColor(statusColor),
              ),
            ),
          ),
          if (explanation.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              appText.explanationLabel,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4.h),
            Text(
              explanation,
              style: TextStyle(
                fontSize: 12.sp,
                height: 1.35,
                color: context.inkColor(Color(0xFF56614F)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
    decoration: BoxDecoration(
      color: context.surfaceColor(Color(0xFFF2F6E7)),
      borderRadius: BorderRadius.circular(10.r),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10.sp,
        color: context.inkColor(Color(0xFF56614F)),
      ),
    ),
  );
}

/// An option, marked as the right answer and/or the user's (wrong) choice.
class _ReviewOptionTile extends StatelessWidget {
  const _ReviewOptionTile({
    required this.label,
    required this.text,
    required this.isCorrectAnswer,
    required this.isUserChoice,
  });

  final String label;
  final String text;
  final bool isCorrectAnswer;
  final bool isUserChoice;

  @override
  Widget build(BuildContext context) {
    final Color? markColor = isCorrectAnswer
        ? _correctColor
        : (isUserChoice ? _incorrectColor : null);
    return Container(
      constraints: BoxConstraints(minHeight: 44.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFF2F6E7)),
        borderRadius: BorderRadius.circular(15.r),
        border: markColor == null
            ? null
            : Border.all(color: context.lineColor(markColor)),
      ),
      child: Row(
        children: [
          Container(
            height: 29.r,
            width: 29.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: context.lineColor(Color(0xFFDDE8B5))),
              shape: BoxShape.circle,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.inkColor(Color(0xFF596254)),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF899580)),
            ),
          ),
          if (isUserChoice)
            Icon(
              Icons.person_rounded,
              size: 16.sp,
              color: context.inkColor(markColor ?? AppColor.primary),
            ),
          if (markColor != null)
            Icon(
              isCorrectAnswer ? Icons.check_circle : Icons.cancel,
              size: 20.sp,
              color: context.inkColor(markColor),
            ),
        ],
      ),
    );
  }
}
