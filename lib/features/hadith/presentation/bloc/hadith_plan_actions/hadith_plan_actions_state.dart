import 'package:islami_app_noorify/core/errors/failures.dart';

enum HadithPlanActionStatus { idle, working, success, failure }

/// Which ⋮ menu action a [HadithPlanActionsState] is reporting on — lets the
/// screen react differently, e.g. switch to "My Complete" only after a
/// completion succeeds.
enum HadithPlanActionKind { delete, complete }

class HadithPlanActionsState {
  const HadithPlanActionsState({
    this.status = HadithPlanActionStatus.idle,
    this.kind,
    this.failure,
  });

  final HadithPlanActionStatus status;

  /// The action this state is reporting on; null only at the initial `idle`.
  final HadithPlanActionKind? kind;

  /// Why the delete or complete failed — the API's own message (set on
  /// failure).
  final Failure? failure;

  bool get isWorking => status == HadithPlanActionStatus.working;
}
