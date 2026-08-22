import 'package:bloc/bloc.dart';

import 'planner_state.dart';

export 'planner_state.dart';

class PlannerCubit extends Cubit<PlannerState> {
  PlannerCubit() : super(const PlannerState());

  void showCompletedPlans(bool value) {
    if (state.showCompletedPlans != value) {
      emit(state.copyWith(showCompletedPlans: value));
    }
  }

  void addQuiz(String planName) {
    emit(
      state.copyWith(
        hasAddedQuiz: true,
        planName: planName.trim().isEmpty ? 'Plan 1' : planName.trim(),
      ),
    );
  }

  void addMoreQuizzes() {
    if (state.hasAddedQuiz) emit(state.copyWith(hasAddedQuiz: false));
  }
}
