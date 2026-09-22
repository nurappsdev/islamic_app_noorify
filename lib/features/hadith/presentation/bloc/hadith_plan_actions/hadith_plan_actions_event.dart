abstract class HadithPlanActionsEvent {
  const HadithPlanActionsEvent();
}

/// Saves a plan's new [name] and / or [targetDays] (`PATCH`).
class EditHadithPlanRequested extends HadithPlanActionsEvent {
  const EditHadithPlanRequested(this.id, {this.name, this.targetDays});

  final String id;
  final String? name;
  final int? targetDays;
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
