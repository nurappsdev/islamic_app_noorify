import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/planner/presentation/bloc/planned_quiz_bloc.dart';
import 'package:islami_app_noorify/features/planner/presentation/quiz_plan_failure_message.dart';
import 'package:islami_app_noorify/features/planner/presentation/widgets/quiz_plan_widgets.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_formatters.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_question_widgets.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_status_view.dart';

/// Plays one quiz of a started plan. Expects a [PlannedQuizBloc] above it.
class PlannedQuizScreen extends StatefulWidget {
  const PlannedQuizScreen({super.key});

  @override
  State<PlannedQuizScreen> createState() => _PlannedQuizScreenState();
}

class _PlannedQuizScreenState extends State<PlannedQuizScreen>
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PlannedQuizBloc>().add(const PlannedQuizTicked());
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onStateChanged(BuildContext context, PlannedQuizState state) {
    final appText = AppText.readOf(context);
    final bloc = context.read<PlannedQuizBloc>();
    switch (state.submissionStatus) {
      case QuizSubmissionStatus.submitted:
        final result = state.result;
        if (result == null) return;
        Navigator.of(context).pushReplacementNamed(
          RouteNames.plannedQuizResult,
          arguments: PlannedQuizResultArgs(
            plan: bloc.plan,
            portion: bloc.portion,
            questions: state.questions,
            result: result,
          ),
        );
      case QuizSubmissionStatus.failed:
        _snack(
          '${appText.quizSubmitFailed}\n'
          '${quizPlanFailureMessage(appText, state.submitFailure, QuizPlanAction.submit)}',
        );
      case QuizSubmissionStatus.idle:
      case QuizSubmissionStatus.submitting:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bloc = context.read<PlannedQuizBloc>();
    return MultiBlocListener(
      listeners: [
        BlocListener<PlannedQuizBloc, PlannedQuizState>(
          listenWhen: (a, b) => a.submissionStatus != b.submissionStatus,
          listener: _onStateChanged,
        ),
        BlocListener<PlannedQuizBloc, PlannedQuizState>(
          listenWhen: (a, b) =>
              b.pageFailure != null && a.pageFailure != b.pageFailure,
          listener: (context, state) => _snack(
            quizPlanFailureMessage(
              appText,
              state.pageFailure,
              QuizPlanAction.questions,
            ),
          ),
        ),
      ],
      child: BlocBuilder<PlannedQuizBloc, PlannedQuizState>(
        builder: (context, state) {
          final Widget body;
          switch (state.loadStatus) {
            case PlannedQuizLoadStatus.loading:
              body = const Center(child: CircularProgressIndicator());
            case PlannedQuizLoadStatus.failure:
              body = QuizStatusView(
                message: quizPlanFailureMessage(
                  appText,
                  state.loadFailure,
                  QuizPlanAction.questions,
                ),
                onRetry: () => bloc.add(const LoadPlannedQuestions()),
              );
            case PlannedQuizLoadStatus.empty:
              body = QuizStatusView(message: appText.noPlannedQuestions);
            case PlannedQuizLoadStatus.success:
              body = _PlannedQuizBody(state: state);
          }
          return PopScope(
            canPop: state.submissionStatus != QuizSubmissionStatus.submitting,
            child: Scaffold(
              backgroundColor: context.pageColor(Colors.white),
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      QuizQuestionAppBar(
                        title: quizPlanPortionTitle(
                          context,
                          bloc.plan,
                          bloc.portion,
                        ),
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
      ),
    );
  }
}

class _PlannedQuizBody extends StatelessWidget {
  const _PlannedQuizBody({required this.state});

  final PlannedQuizState state;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bloc = context.read<PlannedQuizBloc>();
    final question = state.currentQuestion!;
    final total = state.totalQuestions < state.questions.length
        ? state.questions.length
        : state.totalQuestions;
    final selected = state.selectedAnswer;
    final submitting =
        state.submissionStatus == QuizSubmissionStatus.submitting ||
        state.submissionStatus == QuizSubmissionStatus.submitted;
    final failed = state.submissionStatus == QuizSubmissionStatus.failed;
    final showSubmit = state.isLastQuestion || failed;

    final VoidCallback? onPrimary;
    if (submitting || state.isLoadingMore) {
      onPrimary = null;
    } else if (failed) {
      onPrimary = () => bloc.add(const SubmitPlannedQuizAttempt());
    } else if (selected == null) {
      onPrimary = null;
    } else if (state.isLastQuestion) {
      onPrimary = () => bloc.add(const SubmitPlannedQuizAttempt());
    } else {
      onPrimary = () => bloc.add(const NextPlannedQuestion());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 19.h),
        Center(
          child: QuizTimerPill(
            label: context.localizedDigits(
              '${appText.timeSpent} : ${formatClock(state.elapsedSeconds)}',
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
              QuizQuestionProgress(
                value: total == 0 ? 0 : (state.currentIndex + 1) / total,
              ),
              SizedBox(height: 17.h),
              Text(
                context.localized(question.question),
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 10.h),
              for (final option in state.visibleOptions) ...[
                QuizAnswerTile(
                  label: option.key.toLowerCase(),
                  answer: context.localized(option.text),
                  selected: selected == option.key,
                  onTap: state.isLocked
                      ? null
                      : () => bloc.add(SelectPlannedAnswer(option.key)),
                ),
                SizedBox(height: 5.h),
              ],
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Center(
          child: QuizFiftyFiftyButton(
            label: appText.fiftyFiftyChance,
            onTap: state.canUseFiftyFifty
                ? () => bloc.add(const UsePlannedFiftyFifty())
                : null,
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: state.isFirstQuestion || state.isLocked
                    ? null
                    : () => bloc.add(const PreviousPlannedQuestion()),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.fromHeight(45.h),
                  shape: const StadiumBorder(),
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
                child: submitting || state.isLoadingMore
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
