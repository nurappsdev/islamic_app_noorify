import 'package:islami_app_noorify/core/errors/failures.dart';

enum HadithEditPlanStatus { idle, submitting, success, failure }

class HadithEditPlanState {
  const HadithEditPlanState({
    this.status = HadithEditPlanStatus.idle,
    this.failure,
  });

  final HadithEditPlanStatus status;

  /// Why saving failed — the API's own message, e.g. "A plan with this name
  /// already exists" (set on failure).
  final Failure? failure;

  bool get isSubmitting => status == HadithEditPlanStatus.submitting;
}
