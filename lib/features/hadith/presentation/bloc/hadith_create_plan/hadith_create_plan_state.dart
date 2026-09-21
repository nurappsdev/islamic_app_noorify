import 'package:islami_app_noorify/core/errors/failures.dart';

enum HadithCreatePlanStatus { idle, submitting, success, failure }

class HadithCreatePlanState {
  const HadithCreatePlanState({
    this.status = HadithCreatePlanStatus.idle,
    this.planName = '',
    this.failure,
  });

  final HadithCreatePlanStatus status;

  /// The name of the plan that was created (set on success).
  final String planName;

  /// Why creating failed — the API's own message, e.g. "A plan with this name
  /// already exists" (set on failure).
  final Failure? failure;

  bool get isSubmitting => status == HadithCreatePlanStatus.submitting;
}
