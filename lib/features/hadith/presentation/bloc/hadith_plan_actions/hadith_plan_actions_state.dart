import 'package:islami_app_noorify/core/errors/failures.dart';

enum HadithPlanActionStatus { idle, working, success, failure }

class HadithPlanActionsState {
  const HadithPlanActionsState({
    this.status = HadithPlanActionStatus.idle,
    this.failure,
  });

  final HadithPlanActionStatus status;

  /// Why the edit or delete failed — the API's own message, e.g. "A plan with
  /// this name already exists" (set on failure).
  final Failure? failure;

  bool get isWorking => status == HadithPlanActionStatus.working;
}
