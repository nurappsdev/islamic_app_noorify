abstract class HadithPlanActionsEvent {
  const HadithPlanActionsEvent();
}

/// Deletes a plan (`DELETE`).
class DeleteHadithPlanRequested extends HadithPlanActionsEvent {
  const DeleteHadithPlanRequested(this.id);

  final String id;
}

/// Marks a plan as completed (`PATCH`, `{status: "completed"}`) — it leaves
/// "My Plan" and moves to "My Complete".
class CompleteHadithPlanRequested extends HadithPlanActionsEvent {
  const CompleteHadithPlanRequested(this.id);

  final String id;
}
