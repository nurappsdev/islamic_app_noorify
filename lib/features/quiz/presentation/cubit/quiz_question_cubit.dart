import 'package:bloc/bloc.dart';

import 'quiz_question_state.dart';

export 'quiz_question_state.dart';

class QuizQuestionCubit extends Cubit<QuizQuestionState> {
  QuizQuestionCubit() : super(const QuizQuestionState());

  void selectAnswer(int answerIndex) {
    if (state.selectedAnswer != answerIndex) {
      emit(QuizQuestionState(selectedAnswer: answerIndex));
    }
  }
}
