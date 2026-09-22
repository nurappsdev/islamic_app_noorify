import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/domain/usecases/update_hadith_plan.dart';

import 'hadith_edit_plan_event.dart';
import 'hadith_edit_plan_state.dart';

export 'hadith_edit_plan_event.dart';
export 'hadith_edit_plan_state.dart';

class HadithEditPlanBloc extends Bloc<HadithEditPlanEvent, HadithEditPlanState> {
  HadithEditPlanBloc(this._updatePlan) : super(const HadithEditPlanState()) {
    on<SubmitHadithPlanEdit>(_onSubmit);
  }

  final UpdateHadithPlan _updatePlan;

  Future<void> _onSubmit(
    SubmitHadithPlanEdit event,
    Emitter<HadithEditPlanState> emit,
  ) async {
    // A second tap while the first request is running must not save twice.
    if (state.isSubmitting) return;
    emit(const HadithEditPlanState(status: HadithEditPlanStatus.submitting));
    final result = await _updatePlan(
      event.id,
      name: event.name,
      targetDays: event.targetDays,
      bookId: event.bookId,
      categoryIds: event.categoryIds,
      subCategoryIds: event.subCategoryIds,
    );
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(
        HadithEditPlanState(
          status: HadithEditPlanStatus.failure,
          failure: failure,
        ),
      ),
      (_) =>
          emit(const HadithEditPlanState(status: HadithEditPlanStatus.success)),
    );
  }
}
