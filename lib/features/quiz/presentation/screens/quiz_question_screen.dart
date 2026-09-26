import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';
import 'package:islami_app_noorify/features/quiz/presentation/bloc/quiz_question_bloc.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_formatters.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_route_args.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_status_view.dart';

/// Plays one quiz. Expects a [QuizQuestionBloc] above it.
class QuizQuestionScreen extends StatefulWidget {
  const QuizQuestionScreen({super.key});

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Time keeps running in the background; re-read the clock on return so an
  /// expired quiz is handed in straight away.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<QuizQuestionBloc>().add(const QuizTimerTicked());
    }
  }

  void _onStateChanged(BuildContext context, QuizQuestionState state) {
    final appText = AppText.readOf(context);
    switch (state.submissionStatus) {
      case QuizSubmissionStatus.submitted:
        final result = state.result;
        if (result == null) return;
        Navigator.of(context).pushReplacementNamed(
          RouteNames.quizComplete,
          arguments: QuizCompletionArgs(
            result: result,
            launch: context.read<QuizQuestionBloc>().launch,
          ),
        );
      case QuizSubmissionStatus.failed:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                state.submitErrorMessage == null
                    ? appText.quizSubmitFailed
                    : '${appText.quizSubmitFailed}\n${state.submitErrorMessage}',
              ),
            ),
          );
      case QuizSubmissionStatus.idle:
      case QuizSubmissionStatus.submitting:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bloc = context.read<QuizQuestionBloc>();
    final launch = bloc.launch;
    final title = launch.attemptType == QuizAttemptType.daily
        ? appText.dailyQuiz
        : context.localized(launch.categoryName);

    return BlocConsumer<QuizQuestionBloc, QuizQuestionState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus,
      listener: _onStateChanged,
      builder: (context, state) {
        final Widget body;
        switch (state.loadStatus) {
          case QuizLoadStatus.initial:
          case QuizLoadStatus.loading:
            body = const Center(child: CircularProgressIndicator());
          case QuizLoadStatus.failure:
            body = QuizStatusView(
              message: state.loadErrorMessage ?? appText.unableToLoadQuiz,
              onRetry: () => bloc.add(const LoadQuiz()),
            );
          case QuizLoadStatus.empty:
            body = QuizStatusView(message: appText.noQuizAvailable);
          case QuizLoadStatus.success:
            body = _QuizBody(state: state);
        }

        return PopScope(
          // Leaving mid-submission could lose the result; wait for it.
          canPop: state.submissionStatus != QuizSubmissionStatus.submitting,
          child: Scaffold(
            backgroundColor: context.pageColor(Colors.white),
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuizAppBar(
                      title: title.isEmpty ? appText.categoryQuiz : title,
                      onBack: () => Navigator.maybePop(context),
                    ),
                    Expanded(child: body),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuizBody extends StatelessWidget {
  const _QuizBody({required this.state});

  final QuizQuestionState state;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bloc = context.read<QuizQuestionBloc>();
    final question = state.currentQuestion!;
    final total = state.questions.length;
    final selectedAnswer = state.selectedAnswer;
    final submitting =
        state.submissionStatus == QuizSubmissionStatus.submitting ||
        state.submissionStatus == QuizSubmissionStatus.submitted;
    // After a failed submission the only way on is to send it again.
    final showSubmit =
        state.isLastQuestion ||
        state.submissionStatus == QuizSubmissionStatus.failed;
    final VoidCallback? onPrimary;
    if (submitting) {
      onPrimary = null;
    } else if (state.submissionStatus == QuizSubmissionStatus.failed) {
      onPrimary = () => bloc.add(const SubmitQuiz());
    } else if (selectedAnswer == null) {
      onPrimary = null;
    } else if (state.isLastQuestion) {
      onPrimary = () => bloc.add(const SubmitQuiz());
    } else {
      onPrimary = () => bloc.add(const GoToNextQuestion());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 19.h),
        Center(
          child: _TimerPill(
            label: context.localizedDigits(
              fillTemplate(appText.quizTimeRemaining, {
                'time': formatClock(
                  state.isTimed ? state.remainingSeconds : state.elapsedSeconds,
                ),
              }),
            ),
          ),
        ),
        SizedBox(height: 18.h),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Text(
                context.localizedDigits(
                  fillTemplate(appText.quizQuestionOfTotal, {
                    'current': state.currentIndex + 1,
                    'total': total,
                  }),
                ),
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 14.h),
              _QuestionProgress(value: (state.currentIndex + 1) / total),
              SizedBox(height: 17.h),
              Text(
                context.localized(question.question),
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 10.h),
              for (final option in question.options) ...[
                _AnswerTile(
                  label: option.key.toLowerCase(),
                  answer: context.localized(option.text),
                  selected: selectedAnswer == option.key,
                  onTap: state.isLocked
                      ? null
                      : () => bloc.add(SelectAnswer(option.key)),
                ),
                SizedBox(height: 5.h),
              ],
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 15.h),
            decoration: BoxDecoration(
              color: context.surfaceColor(Color(0xFFDDE8B5)),
              borderRadius: BorderRadius.circular(28.r),
            ),
            child: Text(
              appText.fiftyFiftyChance,
              style: TextStyle(
                color: context.inkColor(Color(0xFF5F8671)),
                fontSize: 18.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: 21.h),
        Center(
          child: Text(
            appText.quizTimingProgress,
            style: TextStyle(
              color: context.inkColor(Color(0xFF5D876A)),
              fontSize: 13.sp,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        _TimingProgress(value: state.timeProgress),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: state.isFirstQuestion || state.isLocked
                    ? null
                    : () => bloc.add(const GoToPreviousQuestion()),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.fromHeight(45.h),
                  shape: StadiumBorder(),
                  side: BorderSide(color: context.lineColor(Color(0xFFE0E0E0))),
                ),
                child: Text(
                  appText.previous,
                  style: TextStyle(fontSize: 13.sp),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: FilledButton(
                onPressed: onPrimary,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF879765),
                  disabledBackgroundColor: context.surfaceColor(
                    Color(0xFFE2E2E2),
                  ),
                  minimumSize: Size.fromHeight(45.h),
                ),
                child: submitting
                    ? SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        showSubmit ? appText.submit : appText.next,
                        style: TextStyle(fontSize: 13.sp),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuizAppBar extends StatelessWidget {
  const _QuizAppBar({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38.h,
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 48.w),
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

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 13.h),
    decoration: BoxDecoration(
      color: AppColor.primary,
      borderRadius: BorderRadius.circular(28.r),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time_rounded, color: Colors.white, size: 22.sp),
        SizedBox(width: 10.w),
        Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
        ),
      ],
    ),
  );
}

class _QuestionProgress extends StatelessWidget {
  const _QuestionProgress({required this.value});

  /// Share of the questions reached, 0-1.
  final double value;

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          height: 8.h,
          decoration: BoxDecoration(
            color: context.surfaceColor(Color(0xFFE9E9E9)),
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            height: 8.h,
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
        ),
        Align(
          alignment: Alignment(progress * 2 - 1, 0),
          child: Container(
            width: 22.r,
            height: 22.r,
            decoration: const BoxDecoration(
              color: AppColor.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.label,
    required this.answer,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String answer;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.surfaceColor(Color(0xFFF2F6E7)),
    borderRadius: BorderRadius.circular(15.r),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        // Grows for a long answer instead of clipping it.
        constraints: BoxConstraints(minHeight: 48.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
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
                answer,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF899580),
                ),
              ),
            ),
            if (selected)
              Container(
                height: 24.r,
                width: 24.r,
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.lineColor(Colors.white),
                    width: 2,
                  ),
                ),
                child: const SizedBox(),
              ),
          ],
        ),
      ),
    ),
  );
}

class _TimingProgress extends StatelessWidget {
  const _TimingProgress({required this.value});

  /// Share of the time limit used, 0-1.
  final double value;

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    return Container(
      height: 55.h,
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFDDE8B5)),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Align(
        alignment: Alignment(progress * 2 - 1, 0),
        child: Container(
          width: 58.r,
          height: 58.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.surfaceColor(Color(0xFFDDE8B5)),
            shape: BoxShape.circle,
            border: Border.all(
              color: context.lineColor(Colors.white.withValues(alpha: .7)),
            ),
          ),
          child: Text(
            context.localizedDigits('${(progress * 100).round()} %'),
            style: TextStyle(
              color: context.inkColor(Color(0xFF5D876A)),
              fontSize: 13.sp,
            ),
          ),
        ),
      ),
    );
  }
}
