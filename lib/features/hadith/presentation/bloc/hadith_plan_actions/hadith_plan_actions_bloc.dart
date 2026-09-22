import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/delete_hadith_plan.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/update_hadith_plan.dart';

import 'hadith_plan_actions_event.dart';
import 'hadith_plan_actions_state.dart';

export 'hadith_plan_actions_event.dart';
export 'hadith_plan_actions_state.dart';

/// Editing, deleting and completing a plan from the planner's ⋮ menu. Each
/// ends in `success` (the planner reloads its lists) or `failure` (it shows
/// why).
class HadithPlanActionsBloc
    extends Bloc<HadithPlanActionsEvent, HadithPlanActionsState> {
  HadithPlanActionsBloc(this._update, this._delete)
    : super(const HadithPlanActionsState()) {
    on<EditHadithPlanRequested>(
      (event, emit) => _run(
        emit,
        () => _update(event.id, name: event.name, targetDays: event.targetDays),
      ),
    );
    on<DeleteHadithPlanRequested>(
      (event, emit) => _run(emit, () => _delete(event.id)),
    );
    on<CompleteHadithPlanRequested>(
      (event, emit) =>
          _run(emit, () => _update(event.id, status: 'completed')),
    );
  }

  final UpdateHadithPlan _update;
  final DeleteHadithPlan _delete;

  Future<void> _run(
    Emitter<HadithPlanActionsState> emit,
    Future<Either<Failure, Unit>> Function() action,
  ) async {
    // One at a time: a second tap while the first is still running is ignored.
    if (state.isWorking) return;
    emit(const HadithPlanActionsState(status: HadithPlanActionStatus.working));
    final result = await action();
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(
        HadithPlanActionsState(
          status: HadithPlanActionStatus.failure,
          failure: failure,
        ),
      ),
      (_) => emit(
        const HadithPlanActionsState(status: HadithPlanActionStatus.success),
      ),
    );
  }
}
