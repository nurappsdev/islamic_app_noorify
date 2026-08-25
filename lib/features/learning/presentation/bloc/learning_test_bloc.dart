import 'package:bloc/bloc.dart';

import 'learning_test_event.dart';
import 'learning_test_state.dart';

export 'learning_test_event.dart';
export 'learning_test_state.dart';

class LearningTestBloc extends Bloc<LearningTestEvent, LearningTestState> {
  LearningTestBloc() : super(const LearningTestState()) {
    on<ToggleAnswer>((event, emit) {
      final selectedAnswers = Set<int>.of(state.selectedAnswers);
      if (!selectedAnswers.add(event.answerIndex)) {
        selectedAnswers.remove(event.answerIndex);
      }
      emit(
        LearningTestState(selectedAnswers: Set.unmodifiable(selectedAnswers)),
      );
    });
  }
}
