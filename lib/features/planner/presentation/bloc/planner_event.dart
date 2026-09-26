import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';

abstract class PlannerEvent {
  const PlannerEvent();
}

/// Loads the first page of plans; also used by Try Again and to refresh.
class LoadQuizPlans extends PlannerEvent {
  const LoadQuizPlans();
}

/// Appends the next page, when there is one.
class LoadMoreQuizPlans extends PlannerEvent {
  const LoadMoreQuizPlans();
}

class ShowCompletedPlans extends PlannerEvent {
  const ShowCompletedPlans(this.value);

  final bool value;
}

/// A plan changed elsewhere (created, edited, started, played): put the
/// server's copy in the list.
class QuizPlanChanged extends PlannerEvent {
  const QuizPlanChanged(this.plan);

  final QuizPlan plan;
}

class UpdateQuizPlanRequested extends PlannerEvent {
  const UpdateQuizPlanRequested(this.planId, this.update);

  final String planId;
  final QuizPlanUpdate update;
}

class AbandonQuizPlanRequested extends PlannerEvent {
  const AbandonQuizPlanRequested(this.planId);

  final String planId;
}
