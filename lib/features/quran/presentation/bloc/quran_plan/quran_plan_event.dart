import 'package:islami_app_noorify/features/quran/domain/quran_plan.dart';

sealed class QuranPlanEvent {
  const QuranPlanEvent();
}

/// Loads initial page of plans for [status] (`'in_progress'` or `'completed'`),
/// or both if [status] is null.
final class LoadQuranPlans extends QuranPlanEvent {
  const LoadQuranPlans({this.status, this.forceRefresh = false});

  final String? status;
  final bool forceRefresh;
}

/// Loads next page for [status].
final class LoadMoreQuranPlans extends QuranPlanEvent {
  const LoadMoreQuranPlans({required this.status});

  final String status;
}

/// Submits a new plan to `POST /quran/plans`.
final class CreateQuranPlanSubmitted extends QuranPlanEvent {
  const CreateQuranPlanSubmitted(this.request);

  final CreateQuranPlanRequest request;
}

/// Updates status of an existing plan to `PATCH /quran/plans/{planId}`.
final class UpdateQuranPlanStatus extends QuranPlanEvent {
  const UpdateQuranPlanStatus({
    required this.planId,
    required this.status,
  });

  final String planId;
  final String status;
}
