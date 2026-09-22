import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/delete_hadith_plan.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/update_hadith_plan.dart';

import 'hadith_plan_actions_event.dart';
import 'hadith_plan_actions_state.dart';

export 'hadith_plan_actions_event.dart';
export 'hadith_plan_actions_state.dart';

/// Deleting and completing a plan from the planner's ⋮ menu (editing is its
/// own screen and bloc, [HadithEditPlanBloc]). Each ends in `success` (the
/// planner reloads its lists) or `failure` (it shows why).
class HadithPlanActionsBloc
    extends Bloc<HadithPlanActionsEvent, HadithPlanActionsState> {
  HadithPlanActionsBloc(this._update, this._delete)
    : super(const HadithPlanActionsState()) {
    on<DeleteHadithPlanRequested>(
      (event, emit) =>
          _run(emit, HadithPlanActionKind.delete, () => _delete(event.id)),
    );
    on<CompleteHadithPlanRequested>(
      (event, emit) => _run(
        emit,
        HadithPlanActionKind.complete,
        () => _update(event.id, status: 'completed'),
      ),
    );
  }

  final UpdateHadithPlan _update;
  final DeleteHadithPlan _delete;

  Future<void> _run(
    Emitter<HadithPlanActionsState> emit,
    HadithPlanActionKind kind,
    Future<Either<Failure, Unit>> Function() action,
  ) async {
    // One at a time: a second tap while the first is still running is ignored.
    if (state.isWorking) return;
    emit(
      HadithPlanActionsState(status: HadithPlanActionStatus.working, kind: kind),
    );
    final result = await action();
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(
        HadithPlanActionsState(
          status: HadithPlanActionStatus.failure,
          kind: kind,
          failure: failure,
        ),
      ),
      (_) => emit(
        HadithPlanActionsState(status: HadithPlanActionStatus.success, kind: kind),
      ),
    );
  }
}
