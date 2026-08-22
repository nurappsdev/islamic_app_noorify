import 'package:bloc/bloc.dart';

import 'learning_test_state.dart';

export 'learning_test_state.dart';

class LearningTestCubit extends Cubit<LearningTestState> {
  LearningTestCubit() : super(const LearningTestState());

  void toggleAnswer(int answerIndex) {
    final selectedAnswers = Set<int>.of(state.selectedAnswers);
    if (!selectedAnswers.add(answerIndex)) selectedAnswers.remove(answerIndex);
    emit(LearningTestState(selectedAnswers: Set.unmodifiable(selectedAnswers)));
  }
}
