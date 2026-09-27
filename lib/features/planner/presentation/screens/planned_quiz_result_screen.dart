import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/presentation/bloc/quiz_plan_detail_bloc.dart';
import 'package:islami_app_noorify/features/planner/presentation/widgets/quiz_plan_widgets.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_formatters.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_attempt_card.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_stat_grid.dart';

const _correctColor = Color(0xFF20C664);
const _incorrectColor = Color(0xFFC90009);
const _unansweredColor = Color(0xFF9E9E9E);

/// The server-scored result of a planned quiz, the plan's progress as the
/// server now reports it, and the way on. Expects a [QuizPlanDetailBloc] for
/// the plan above it.
class PlannedQuizResultScreen extends StatelessWidget {
  const PlannedQuizResultScreen({super.key, required this.args});

  final PlannedQuizResultArgs args;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final result = args.result;
    final answerOf = {for (final a in result.answers) a.questionId: a};
    final detail = context.watch<QuizPlanDetailBloc>().state;
    final plan = detail.plan;
    final next = plan?.canContinue == true ? plan!.nextPortion : null;
    // Plan quizzes earn no amol points; show points only if the server gave
    // some.
    final showPoints = result.pointsEarned > 0 || result.amol != null;

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 0),
              child: _ResultHeader(
                title: quizPlanPortionTitle(context, args.plan, args.portion),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 16.h),
                children: [
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: context.surfaceColor(Color(0xFFDFE9B9)),
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Column(
                      children: [
                        QuizScoreRing(scorePercentage: result.scorePercentage),
                        SizedBox(height: 12.h),
                        QuizStatGrid(
                          stats: [
                            (appText.questionsWord, '${result.totalQuestions}'),
                            (
                              appText.correctAnswers,
                              '${result.correctAnswers}',
                            ),
                            (
                              appText.incorrectAnswers,
                              '${result.incorrectAnswers}',
                            ),
                            (
                              appText.unansweredLabel,
                              result.unansweredQuestions == null
                                  ? '—'
                                  : '${result.unansweredQuestions}',
                            ),
                            (
                              appText.accuracy,
                              formatOptional(
                                result.accuracyPercentage,
                                formatPercent,
                              ),
                            ),
                            (
                              appText.scoreLabel,
                              formatPercent(result.scorePercentage),
                            ),
                            if (showPoints)
                              (
                                appText.pointsWord,
                                '${formatPoints(result.pointsEarned)} / '
                                    '${formatPoints(result.maxPoints)}',
                              ),
                            (
                              appText.timeSpent,
                              formatClock(result.timeSpentSeconds),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (plan != null)
                    _PlanProgressCard(plan: plan)
                  else
                    Padding(
                      padding: EdgeInsets.all(12.h),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  SizedBox(height: 12.h),
                  Text(
                    appText.reviewAnswers,
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  SizedBox(height: 8.h),
                  for (var i = 0; i < args.questions.length; i++) ...[
                    _AnsweredQuestion(
                      number: i + 1,
                      question: args.questions[i],
                      answer: answerOf[args.questions[i].id],
                    ),
                    SizedBox(height: 8.h),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 9.h),
              child: Column(
                children: [
                  if (next != null)
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pushReplacementNamed(
                              RouteNames.plannedQuiz,
                              arguments: PlannedQuizArgs(
                                plan: plan!,
                                portion: next,
                              ),
                            ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFA1AD59),
                        ),
                        child: Text(appText.nextQuizLabel),
                      ),
                    ),
                  SizedBox(height: 6.h),
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.primary,
                        side: const BorderSide(color: AppColor.primary),
                      ),
                      child: Text(appText.backToPlan),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 35.h,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFDFDE68),
              foregroundColor: const Color(0xFF303629),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 44.w),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColor.primary, fontSize: 18.sp),
          ),
        ),
      ],
    ),
  );
}

/// The plan's progress after this quiz, as the server reports it.
class _PlanProgressCard extends StatelessWidget {
  const _PlanProgressCard({required this.plan});

  final QuizPlan plan;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
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
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              QuizPlanStatusChip(plan: plan),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: (plan.completionPercentage / 100).clamp(0, 1).toDouble(),
              minHeight: 6.h,
              color: const Color(0xFF5D896D),
              backgroundColor: context.surfaceColor(Color(0xFFF0F0F6)),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            context.localizedDigits(
              '${fillTemplate(appText.quizzesCompletedLabel, {'done': plan.completedQuizzes, 'total': plan.totalQuizzes})} · '
              '${fillTemplate(appText.percentCompleteLabel, {'percent': formatPoints(plan.completionPercentage)})}',
            ),
            style: TextStyle(fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}

/// A question as it was asked, marked from the server's answer result.
class _AnsweredQuestion extends StatelessWidget {
  const _AnsweredQuestion({
    required this.number,
    required this.question,
    required this.answer,
  });

  final int number;
  final PlannedQuestion question;

  /// `null` when the server's result does not list this question.
  final PlannedAnswerResult? answer;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final checkedBy = answer?.checkedBy;
    final (color, icon) = checkedBy == null
        ? (_unansweredColor, Icons.remove)
        : (answer!.isCorrect
              ? (_correctColor, Icons.check)
              : (_incorrectColor, Icons.close));
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
        borderRadius: BorderRadius.circular(16.r),
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
                      context.localized(question.question),
                  style: TextStyle(fontSize: 13.sp),
                ),
              ),
              SizedBox(width: 8.w),
              CircleAvatar(
                radius: 11.r,
                backgroundColor: context.surfaceColor(color),
                child: Icon(icon, color: Colors.white, size: 14.sp),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          for (final option in question.options)
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: _OptionLine(
                label: option.key.toLowerCase(),
                text: context.localized(option.text),
                isCorrectAnswer: option.key == answer?.correctAnswerKey,
                isUserChoice: option.key == checkedBy,
              ),
            ),
          if (checkedBy == null)
            Text(
              appText.notAnswered,
              style: TextStyle(
                fontSize: 11.sp,
                color: context.inkColor(_incorrectColor),
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionLine extends StatelessWidget {
  const _OptionLine({
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
    final Color? mark = isCorrectAnswer
        ? _correctColor
        : (isUserChoice ? _incorrectColor : null);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFF2F6E7)),
        borderRadius: BorderRadius.circular(12.r),
        border: mark == null
            ? null
            : Border.all(color: context.lineColor(mark)),
      ),
      child: Row(
        children: [
          Text('$label.', style: TextStyle(fontSize: 12.sp)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.sp)),
          ),
          if (isUserChoice)
            Icon(
              Icons.person_rounded,
              size: 15.sp,
              color: context.inkColor(mark ?? AppColor.primary),
            ),
          if (mark != null)
            Icon(
              isCorrectAnswer ? Icons.check_circle : Icons.cancel,
              size: 18.sp,
              color: context.inkColor(mark),
            ),
        ],
      ),
    );
  }
}
