import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/app_route_observer.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/planner/domain/entities/quiz_plan.dart';
import 'package:tuhfatul_muslim/features/planner/presentation/bloc/quiz_plan_detail_bloc.dart';
import 'package:tuhfatul_muslim/features/planner/presentation/quiz_plan_failure_message.dart';
import 'package:tuhfatul_muslim/features/planner/presentation/widgets/quiz_plan_widgets.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_formatters.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_navigation.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_status_view.dart';

/// One quiz plan (`GET /quizzes/plans/{id}`): its schedule, progress and
/// quizzes, and Start / Continue as its status allows. Expects a
/// [QuizPlanDetailBloc] above it.
class PlannerDetailScreen extends StatefulWidget {
  const PlannerDetailScreen({super.key, required this.initialTitle});

  /// Shown in the header until the plan has loaded.
  final String initialTitle;

  @override
  State<PlannerDetailScreen> createState() => _PlannerDetailScreenState();
}

class _PlannerDetailScreenState extends State<PlannerDetailScreen>
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

  /// Back from a quiz or its result: reload the plan's progress.
  @override
  void didPopNext() =>
      context.read<QuizPlanDetailBloc>().add(const LoadQuizPlanDetail());

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onStateChanged(BuildContext context, QuizPlanDetailState state) {
    final notice = state.notice;
    final appText = AppText.readOf(context);
    if (notice != null && notice.failure != null) {
      _snack(quizPlanFailureMessage(appText, notice.failure, notice.action));
    } else if (notice?.action == QuizPlanAction.update) {
      _snack(appText.planUpdated);
    } else if (notice?.action == QuizPlanAction.abandon) {
      _snack(appText.planAbandoned);
    }
  }

  /// Started: go straight to the first quiz still to be played.
  void _onStarted(BuildContext context, QuizPlanDetailState state) {
    final plan = state.plan;
    final portion = plan?.nextPortion;
    if (plan != null && portion != null) {
      openPlannedQuiz(context, plan, portion);
    }
  }

  Future<void> _edit(QuizPlan plan) async {
    final update = await showEditQuizPlanDialog(context, plan);
    if (update == null || !mounted) return;
    context.read<QuizPlanDetailBloc>().add(
      UpdateQuizPlanDetailRequested(update),
    );
  }

  Future<void> _abandon(QuizPlan plan) async {
    if (!await showAbandonQuizPlanDialog(context, name: plan.name) ||
        !mounted) {
      return;
    }
    context.read<QuizPlanDetailBloc>().add(
      const AbandonQuizPlanDetailRequested(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bloc = context.read<QuizPlanDetailBloc>();
    return MultiBlocListener(
      listeners: [
        BlocListener<QuizPlanDetailBloc, QuizPlanDetailState>(
          listenWhen: (a, b) => a.notice != b.notice,
          listener: _onStateChanged,
        ),
        BlocListener<QuizPlanDetailBloc, QuizPlanDetailState>(
          listenWhen: (a, b) => a.startedSerial != b.startedSerial,
          listener: _onStarted,
        ),
      ],
      child: BlocBuilder<QuizPlanDetailBloc, QuizPlanDetailState>(
        builder: (context, state) {
          final plan = state.plan;
          final Widget body;
          if (plan != null) {
            body = _PlanDetailBody(plan: plan, busy: state.busyAction);
          } else if (state.status == QuizPlanDetailStatus.failure) {
            body = QuizStatusView(
              message: quizPlanFailureMessage(
                appText,
                state.failure,
                QuizPlanAction.load,
              ),
              onRetry: state.failure?.statusCode == 404
                  ? null
                  : () => bloc.add(const LoadQuizPlanDetail()),
            );
          } else {
            body = const Center(child: CircularProgressIndicator());
          }
          return Scaffold(
            backgroundColor: context.pageColor(Colors.white),
            body: SafeArea(
              child: Column(
                children: [
                  _PlannerHeader(
                    title: plan?.name ?? widget.initialTitle,
                    onBack: () => Navigator.of(context).pop(),
                    trailing: plan == null || state.busyAction != null
                        ? null
                        : QuizPlanMenu(
                            plan: plan,
                            onEdit: () => _edit(plan),
                            onAbandon: () => _abandon(plan),
                          ),
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlanDetailBody extends StatelessWidget {
  const _PlanDetailBody({required this.plan, required this.busy});

  final QuizPlan plan;
  final QuizPlanAction? busy;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bloc = context.read<QuizPlanDetailBloc>();
    final next = plan.nextPortion;
    // Only what the server's status allows.
    final (String? label, VoidCallback? action) = plan.canStart
        ? (appText.startLabel, () => bloc.add(const StartQuizPlanRequested()))
        : plan.canContinue && next != null
        ? (appText.continueLabel, () => openPlannedQuiz(context, plan, next))
        : (null, null);
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => bloc.add(const LoadQuizPlanDetail()),
            child: ListView(
              padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 18.h),
              children: [
                _PlanSummary(plan: plan),
                SizedBox(height: 12.h),
                for (final portion in plan.portions) ...[
                  _PlanQuizCard(
                    plan: plan,
                    portion: portion,
                    onTap: _portionTap(context, portion),
                  ),
                  SizedBox(height: 7.h),
                ],
              ],
            ),
          ),
        ),
        if (label != null)
          Padding(
            padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 9.h),
            child: SizedBox(
              width: double.infinity,
              height: 52.h,
              child: FilledButton(
                onPressed: busy == null ? action : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFA1AD59),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                ),
                child: busy == QuizPlanAction.start
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(label, style: TextStyle(fontSize: 14.sp)),
              ),
            ),
          ),
      ],
    );
  }

  /// A finished quiz opens its review; an open one plays once started.
  VoidCallback? _portionTap(BuildContext context, QuizPlanPortion portion) {
    final attemptId = portion.attemptId;
    if (portion.isCompleted && attemptId != null) {
      return () => openQuizAttemptReview(context, attemptId);
    }
    if (!portion.isCompleted && plan.status == QuizPlanStatus.inProgress) {
      return () => openPlannedQuiz(context, plan, portion);
    }
    return null;
  }
}

/// The plan's schedule, status and the server's progress figures.
class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan});

  final QuizPlan plan;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
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
              Icon(
                Icons.event_outlined,
                size: 16.sp,
                color: const Color(0xFF5D896D),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  context.localizedDigits(
                    quizPlanScheduleLabel(appText, plan.scheduledAt),
                  ),
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
              QuizPlanStatusChip(plan: plan),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: (plan.completionPercentage / 100).clamp(0, 1).toDouble(),
              minHeight: 6.h,
              color: const Color(0xFF5D896D),
              backgroundColor: context.surfaceColor(Color(0xFFF2F6E7)),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            context.localizedDigits(
              fillTemplate(appText.percentCompleteLabel, {
                'percent': formatPoints(plan.completionPercentage),
              }),
            ),
            style: TextStyle(fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}

class _PlannerHeader extends StatelessWidget {
  const _PlannerHeader({
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.lineColor(Color(0xFFDDE8C1))),
        ),
      ),
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
                minimumSize: Size(33.w, 33.w),
                padding: EdgeInsets.zero,
              ),
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 15.sp),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 44.w),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.inkColor(Color(0xFF84945F)),
                fontSize: 18.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing),
        ],
      ),
    );
  }
}

/// One quiz of the plan, with the server's completion and score.
class _PlanQuizCard extends StatelessWidget {
  const _PlanQuizCard({
    required this.plan,
    required this.portion,
    required this.onTap,
  });

  final QuizPlan plan;
  final QuizPlanPortion portion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final score = portion.scorePercentage;
    final status = portion.isCompleted
        ? '${appText.planStatusCompleted}'
              '${score == null ? '' : ' · ${appText.scoreLabel}: ${formatPercent(score)}'}'
        : appText.notCompletedLabel;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21.r),
      child: Container(
        constraints: BoxConstraints(minHeight: 76.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
          borderRadius: BorderRadius.circular(21.r),
        ),
        child: Row(
          children: [
            _QuizArtwork(done: portion.isCompleted),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quizPlanPortionTitle(context, plan, portion),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    context.localizedDigits(
                      '${portion.totalQuestions} ${appText.questionsWord}',
                    ),
                    style: TextStyle(
                      color: const Color(0xFFA1AD59),
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    context.localizedDigits(status),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: context.inkColor(
                        portion.isCompleted
                            ? const Color(0xFF20C664)
                            : const Color(0xFF929BB6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFFA1AD59),
                size: 22.sp,
              ),
          ],
        ),
      ),
    );
  }
}

class _QuizArtwork extends StatelessWidget {
  const _QuizArtwork({this.done = false});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 47.w,
      height: 47.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
      ),
      child: Icon(
        done ? Icons.check_rounded : Icons.image_outlined,
        color: context.inkColor(Color(0xFF8B9865)),
        size: 23.sp,
      ),
    );
  }
}
