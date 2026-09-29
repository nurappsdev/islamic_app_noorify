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
  const UpdateQuranPlanStatus({required this.planId, required this.status});

  final String planId;
  final String status;
}

/// Loads full details of a plan from `GET /quran/plans/{planId}`.
final class LoadQuranPlanDetails extends QuranPlanEvent {
  const LoadQuranPlanDetails({required this.planId, this.forceRefresh = false});

  final String planId;
  final bool forceRefresh;
}

/// Submits an update request to `PATCH /quran/plans/{planId}`.
final class UpdateQuranPlanSubmitted extends QuranPlanEvent {
  const UpdateQuranPlanSubmitted({required this.planId, required this.request});

  final String planId;
  final UpdateQuranPlanRequest request;
}

/// Completes an existing plan via `PATCH /quran/plans/{planId}/complete`.
final class CompleteQuranPlan extends QuranPlanEvent {
  const CompleteQuranPlan({required this.planId});

  final String planId;
}

/// Deletes an existing plan via `DELETE /quran/plans/{planId}`.
final class DeleteQuranPlan extends QuranPlanEvent {
  const DeleteQuranPlan({required this.planId});

  final String planId;
}

/// Loads initial page of plan ayahs from `GET /quran/plans/{planId}/ayahs`.
final class LoadPlanAyahs extends QuranPlanEvent {
  const LoadPlanAyahs({
    required this.planId,
    this.filter = 'all',
    this.forceRefresh = false,
  });

  final String planId;
  final String filter;
  final bool forceRefresh;
}

/// Loads the next page of plan ayahs.
final class LoadMorePlanAyahs extends QuranPlanEvent {
  const LoadMorePlanAyahs({required this.planId});

  final String planId;
}

/// Changes the active filter (`all`, `read`, `unread`) and reloads page 1.
final class ChangePlanAyahsFilter extends QuranPlanEvent {
  const ChangePlanAyahsFilter({required this.planId, required this.filter});

  final String planId;
  final String filter;
}
