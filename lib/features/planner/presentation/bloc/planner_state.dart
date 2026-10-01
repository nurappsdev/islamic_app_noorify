import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/planner/domain/entities/quiz_plan.dart';
import 'package:tuhfatul_muslim/features/planner/presentation/quiz_plan_failure_message.dart';

enum PlannerStatus { initial, loading, success, failure }

/// A one-off message for the screen: a done action, or a failed one.
class PlannerNotice {
  const PlannerNotice({
    required this.serial,
    required this.action,
    this.failure,
  });

  /// Distinct per notice, so the same message twice is shown twice.
  final int serial;
  final QuizPlanAction action;

  /// `null` when [action] succeeded.
  final Failure? failure;
}

class PlannerState {
  const PlannerState({
    this.showCompletedPlans = false,
    this.status = PlannerStatus.initial,
    this.plans = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
    this.busyPlanIds = const {},
    this.notice,
  });

  final bool showCompletedPlans;
  final PlannerStatus status;

  /// Every plan loaded so far, newest first, as the server sends them.
  final List<QuizPlan> plans;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final Failure? failure;

  /// Plans with an edit or abandon request in flight.
  final Set<String> busyPlanIds;
  final PlannerNotice? notice;

  /// My Plan: plans still open, and any status this build does not know.
  List<QuizPlan> get activePlans => plans
      .where((p) => p.status.isActive || p.status == QuizPlanStatus.unknown)
      .toList();

  /// Complete Plan: finished and abandoned plans.
  List<QuizPlan> get closedPlans => plans
      .where(
        (p) =>
            p.status == QuizPlanStatus.completed ||
            p.status == QuizPlanStatus.abandoned,
      )
      .toList();

  List<QuizPlan> get visiblePlans =>
      showCompletedPlans ? closedPlans : activePlans;

  PlannerState copyWith({
    bool? showCompletedPlans,
    PlannerStatus? status,
    List<QuizPlan>? plans,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? failure,
    Set<String>? busyPlanIds,
    PlannerNotice? notice,
  }) {
    return PlannerState(
      showCompletedPlans: showCompletedPlans ?? this.showCompletedPlans,
      status: status ?? this.status,
      plans: plans ?? this.plans,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: failure ?? this.failure,
      busyPlanIds: busyPlanIds ?? this.busyPlanIds,
      notice: notice ?? this.notice,
    );
  }
}
