import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/app_route_observer.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/core/widgets/login_required_dialog.dart';
import 'package:tuhfatul_muslim/features/planner/domain/entities/quiz_plan.dart';
import 'package:tuhfatul_muslim/features/planner/presentation/bloc/planner_bloc.dart';
import 'package:tuhfatul_muslim/features/planner/presentation/quiz_plan_failure_message.dart';
import 'package:tuhfatul_muslim/features/planner/presentation/widgets/quiz_plan_widgets.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_formatters.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_status_view.dart';
import 'package:tuhfatul_muslim/core/auth/auth_feature.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// The user's quiz plans (`GET /quizzes/plans`), reached from index 2 of the
/// Quiz navigation bar. Expects a [PlannerBloc] above it.
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    if (isUserSignedIn) context.read<PlannerBloc>().add(const LoadQuizPlans());
  }

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

  /// Back from a plan, a quiz or its result: the plans may have moved on.
  @override
  void didPopNext() {
    if (isUserSignedIn) context.read<PlannerBloc>().add(const LoadQuizPlans());
  }

  Future<void> _createPlan() async {
    if (!await requireLogin(context, feature: AuthFeatures.quizPlanner) ||
        !mounted) {
      return;
    }
    // Untyped: the app's routes are built as `MaterialPageRoute<void>`, so a
    // typed push would fail its cast. The screen pops with the created plan.
    final created = await Navigator.of(
      context,
    ).pushNamed(RouteNames.createPlan);
    if (created is! QuizPlan || !mounted) return;
    context.read<PlannerBloc>().add(QuizPlanChanged(created));
    _snack(AppText.readOf(context).planCreated);
  }

  Future<void> _edit(QuizPlan plan) async {
    final update = await showEditQuizPlanDialog(context, plan);
    if (update == null || !mounted) return;
    context.read<PlannerBloc>().add(UpdateQuizPlanRequested(plan.id, update));
  }

  Future<void> _abandon(QuizPlan plan) async {
    if (!await showAbandonQuizPlanDialog(context, name: plan.name) ||
        !mounted) {
      return;
    }
    context.read<PlannerBloc>().add(AbandonQuizPlanRequested(plan.id));
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onNotice(BuildContext context, PlannerState state) {
    final notice = state.notice;
    if (notice == null) return;
    final appText = AppText.readOf(context);
    if (notice.failure != null) {
      _snack(quizPlanFailureMessage(appText, notice.failure, notice.action));
    } else if (notice.action == QuizPlanAction.update) {
      _snack(appText.planUpdated);
    } else if (notice.action == QuizPlanAction.abandon) {
      _snack(appText.planAbandoned);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final language = context.watch<LanguageBloc>().state.language;
    final bloc = context.read<PlannerBloc>();
    return BlocConsumer<PlannerBloc, PlannerState>(
      listenWhen: (previous, current) => previous.notice != current.notice,
      listener: _onNotice,
      builder: (context, state) {
        final Widget body;
        if (!isUserSignedIn) {
          body = _LoginPrompt(
            message: AuthFeatures.of(
              AuthFeatures.quizPlanner,
            ).messageFor(language),
          );
        } else {
          switch (state.status) {
            case PlannerStatus.initial:
            case PlannerStatus.loading:
              body = const Center(child: CircularProgressIndicator());
            case PlannerStatus.failure:
              body = QuizStatusView(
                message: quizPlanFailureMessage(
                  appText,
                  state.failure,
                  QuizPlanAction.load,
                ),
                onRetry: () => bloc.add(const LoadQuizPlans()),
              );
            case PlannerStatus.success:
              body = _PlanList(
                state: state,
                onEdit: _edit,
                onAbandon: _abandon,
              );
          }
        }
        return Scaffold(
          backgroundColor: context.pageColor(Colors.white),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _PlanTabs(
                      showCompletedPlans: state.showCompletedPlans,
                      onTabChanged: (value) =>
                          bloc.add(ShowCompletedPlans(value)),
                    ),
                    SizedBox(height: 12.h),
                    Expanded(child: body),
                  ],
                ),
                if (!state.showCompletedPlans)
                  Positioned(
                    right: 58.w,
                    bottom: 104.h,
                    child: FilledButton.icon(
                      onPressed: _createPlan,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFA1AD59),
                        foregroundColor: Colors.white,
                        minimumSize: Size(127.w, 48.h),
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                      ),
                      icon: Icon(Icons.edit_outlined, size: 20.sp),
                      label: Text(
                        appText.createPlan,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The selected tab's plans, loading more from the server as it scrolls.
class _PlanList extends StatelessWidget {
  const _PlanList({
    required this.state,
    required this.onEdit,
    required this.onAbandon,
  });

  final PlannerState state;
  final ValueChanged<QuizPlan> onEdit;
  final ValueChanged<QuizPlan> onAbandon;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bloc = context.read<PlannerBloc>();
    final plans = state.visiblePlans;
    // The tabs split the server's pages, so a short tab asks for more.
    if (plans.length < 5 && state.hasMore && !state.isLoadingMore) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => bloc.add(const LoadMoreQuizPlans()),
      );
    }
    if (plans.isEmpty) {
      if (state.hasMore || state.isLoadingMore) {
        return const Center(child: CircularProgressIndicator());
      }
      return Transform.translate(
        offset: Offset(0, -34.h),
        child: _EmptyPlans(
          message: state.showCompletedPlans
              ? appText.noCompletedPlansMessage
              : appText.noPlansYetMessage,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => bloc.add(const LoadQuizPlans()),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 200) {
            bloc.add(const LoadMoreQuizPlans());
          }
          return false;
        },
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 170.h),
          itemCount: plans.length + (state.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, _) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            if (index >= plans.length) {
              return Padding(
                padding: EdgeInsets.all(12.h),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            final plan = plans[index];
            return _PlanCard(
              plan: plan,
              busy: state.busyPlanIds.contains(plan.id),
              onOpen: () => openQuizPlanDetail(context, plan),
              onEdit: () => onEdit(plan),
              onAbandon: () => onAbandon(plan),
            );
          },
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: 12.h),
            FilledButton(
              onPressed: () => showLoginRequiredDialog(
                context,
                feature: AuthFeatures.quizPlanner,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA1AD59),
              ),
              child: Text(AppText.of(context).login),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTabs extends StatelessWidget {
  const _PlanTabs({
    required this.showCompletedPlans,
    required this.onTabChanged,
  });

  final bool showCompletedPlans;
  final ValueChanged<bool> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(72.w, 7.h, 72.w, 0),
      child: SizedBox(
        height: 36.h,
        child: Row(
          children: [
            _PlanTab(
              label: appText.myPlan,
              selected: !showCompletedPlans,
              onPressed: () => onTabChanged(false),
            ),
            Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 1.h,
                      color: context.surfaceColor(Color(0xFFDDE8C1)),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: _PlanTab(
                      label: appText.completePlan,
                      selected: showCompletedPlans,
                      onPressed: () => onTabChanged(true),
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

class _PlanTab extends StatelessWidget {
  const _PlanTab({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: 112.w,
          height: 36.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.surfaceColor(
              selected ? const Color(0xFFDDE8BA) : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  const _EmptyPlans({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100.w,
            height: 91.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.sticky_note_2_rounded,
                  color: const Color(0xFFDDE8BA),
                  size: 86.sp,
                ),
                Positioned(
                  top: 27.h,
                  child: Text(
                    '?',
                    style: TextStyle(
                      color: context.inkColor(Color(0xFF84945F)),
                      fontSize: 31.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  top: 18.h,
                  left: 6.w,
                  child: Icon(
                    Icons.wb_sunny_outlined,
                    color: context.inkColor(Color(0xFF84945F)),
                    size: 25.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 13.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF989898),
              fontSize: 13.sp,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// A plan with the server's progress: name, schedule, status, questions,
/// quizzes done, and its categories.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.busy,
    required this.onOpen,
    required this.onEdit,
    required this.onAbandon,
  });

  final QuizPlan plan;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onAbandon;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final muted = context.inkColor(const Color(0xFF929BB6));
    final categories = {
      for (final portion in plan.portions)
        context.localized(portion.categoryName),
    }.where((name) => name.isNotEmpty).join(', ');
    // Only what the server's status allows.
    final action = plan.canStart
        ? appText.startLabel
        : (plan.canContinue ? appText.continueLabel : null);
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(21.r),
      child: Container(
        padding: EdgeInsets.fromLTRB(4.w, 10.h, 4.w, 10.h),
        decoration: BoxDecoration(
          border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
          borderRadius: BorderRadius.circular(21.r),
        ),
        child: Row(
          children: [
            const _PlanArtwork(),
            SizedBox(width: 9.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The status drops below the name when both do not fit.
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 3.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        plan.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.inkColor(Color(0xFF332B57)),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      QuizPlanStatusChip(plan: plan),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    context.localizedDigits(
                      quizPlanScheduleLabel(appText, plan.scheduledAt),
                    ),
                    style: TextStyle(color: muted, fontSize: 11.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    context.localizedDigits(
                      '${plan.totalQuestions} ${appText.questionsWord} · '
                      '${fillTemplate(appText.quizzesCompletedLabel, {'done': plan.completedQuizzes, 'total': plan.totalQuizzes})}',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 11.sp),
                  ),
                  if (categories.isNotEmpty)
                    Text(
                      categories,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 11.sp),
                    ),
                  SizedBox(height: 6.h),
                  _PlanProgress(plan: plan),
                ],
              ),
            ),
            SizedBox(width: 6.w),
            if (busy)
              SizedBox(
                width: 20.r,
                height: 20.r,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            else if (action != null)
              FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: context.surfaceColor(Color(0xFFDDE8BA)),
                  foregroundColor: context.inkColor(Color(0xFF303629)),
                  minimumSize: Size(72.w, 36.h),
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(action, style: TextStyle(fontSize: 12.sp)),
              ),
            SizedBox(width: 4.w),
            QuizPlanMenu(plan: plan, onEdit: onEdit, onAbandon: onAbandon),
          ],
        ),
      ),
    );
  }
}

/// The server's completion percentage as a bar.
class _PlanProgress extends StatelessWidget {
  const _PlanProgress({required this.plan});

  final QuizPlan plan;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: (plan.completionPercentage / 100).clamp(0, 1).toDouble(),
            minHeight: 5.h,
            color: const Color(0xFFA1AD59),
            backgroundColor: context.surfaceColor(Color(0xFFF0F0F6)),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          context.localizedDigits(
            fillTemplate(appText.percentCompleteLabel, {
              'percent': formatPoints(plan.completionPercentage),
            }),
          ),
          style: TextStyle(fontSize: 10.sp, color: const Color(0xFFA1AD59)),
        ),
      ],
    );
  }
}

class _PlanArtwork extends StatelessWidget {
  const _PlanArtwork();

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
        Icons.image_outlined,
        color: context.inkColor(Color(0xFF8B9865)),
        size: 23.sp,
      ),
    );
  }
}
