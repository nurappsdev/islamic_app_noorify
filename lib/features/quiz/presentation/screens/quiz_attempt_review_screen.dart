import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/presentation/bloc/quiz_attempt_review_bloc.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_formatters.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_attempt_card.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_status_view.dart';

const _correctColor = Color(0xFF20C664);
const _incorrectColor = Color(0xFFC90009);

/// Question-by-question review of a finished attempt. Correctness and the
/// right answer come from the server. Expects a [QuizAttemptReviewBloc].
class QuizAttemptReviewScreen extends StatelessWidget {
  const QuizAttemptReviewScreen({super.key});

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
                              message:
                                  state.errorMessage ??
                                  appText.unableToLoadAttempt,
                              onRetry: () => context
                                  .read<QuizAttemptReviewBloc>()
                                  .add(const LoadQuizAttemptReview()),
                            );
                          case QuizAttemptReviewStatus.success:
                            if (detail == null) return const SizedBox();
                            return ListView.separated(
                              padding: EdgeInsets.only(bottom: 24.h),
                              itemCount: detail.questions.length + 1,
                              separatorBuilder: (_, _) =>
                                  SizedBox(height: 10.h),
                              itemBuilder: (context, index) => index == 0
                                  ? _AttemptOverview(attempt: detail.attempt)
                                  : _ReviewQuestionCard(
                                      number: index,
                                      question: detail.questions[index - 1],
                                    ),
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

class _AttemptOverview extends StatelessWidget {
  const _AttemptOverview({required this.attempt});

  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
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
      child: Row(
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
                line(appText.timeSpent, formatClock(attempt.timeSpentSeconds)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewQuestionCard extends StatelessWidget {
  const _ReviewQuestionCard({required this.number, required this.question});

  final int number;
  final QuizReviewQuestion question;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final text = context.localized(question.question);
    final explanation = context.localized(question.explanation);
    final statusColor = question.isCorrect ? _correctColor : _incorrectColor;
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
              CircleAvatar(
                radius: 12.r,
                backgroundColor: context.surfaceColor(statusColor),
                child: Icon(
                  question.isCorrect ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 15.sp,
                ),
              ),
            ],
          ),
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
          if (question.checkedBy == null)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                appText.notAnswered,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.inkColor(_incorrectColor),
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
