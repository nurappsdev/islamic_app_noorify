import 'package:bloc/bloc.dart';

import 'planner_event.dart';
import 'planner_state.dart';

export 'planner_event.dart';
export 'planner_state.dart';

class PlannerBloc extends Bloc<PlannerEvent, PlannerState> {
  PlannerBloc() : super(const PlannerState()) {
    on<ShowCompletedPlans>((event, emit) {
      if (state.showCompletedPlans != event.value) {
        emit(state.copyWith(showCompletedPlans: event.value));
      }
    });

    on<AddQuiz>((event, emit) {
      emit(
        state.copyWith(
          hasAddedQuiz: true,
          planName: event.planName.trim().isEmpty
              ? 'Plan 1'
              : event.planName.trim(),
        ),
      );
    });

    on<AddMoreQuizzes>((event, emit) {
      if (state.hasAddedQuiz) emit(state.copyWith(hasAddedQuiz: false));
    });
  }
}
