import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/domain/usecases/create_hadith_plan.dart';

import 'hadith_create_plan_event.dart';
import 'hadith_create_plan_state.dart';

export 'hadith_create_plan_event.dart';
export 'hadith_create_plan_state.dart';

class HadithCreatePlanBloc
    extends Bloc<HadithCreatePlanEvent, HadithCreatePlanState> {
  HadithCreatePlanBloc(this._createPlan)
    : super(const HadithCreatePlanState()) {
    on<SubmitHadithPlan>(_onSubmit);
  }

  final CreateHadithPlan _createPlan;

  Future<void> _onSubmit(
    SubmitHadithPlan event,
    Emitter<HadithCreatePlanState> emit,
  ) async {
    // A second tap while the first request is running must not create the
    // plan twice.
    if (state.isSubmitting) return;
    emit(
      const HadithCreatePlanState(status: HadithCreatePlanStatus.submitting),
    );
    final result = await _createPlan(event.draft);
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(
        HadithCreatePlanState(
          status: HadithCreatePlanStatus.failure,
          failure: failure,
        ),
      ),
      (_) => emit(
        HadithCreatePlanState(
          status: HadithCreatePlanStatus.success,
          planName: event.draft.name,
        ),
      ),
    );
  }
}
