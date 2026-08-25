import 'package:bloc/bloc.dart';

import 'quiz_question_event.dart';
import 'quiz_question_state.dart';

export 'quiz_question_event.dart';
export 'quiz_question_state.dart';

class QuizQuestionBloc extends Bloc<QuizQuestionEvent, QuizQuestionState> {
  QuizQuestionBloc() : super(const QuizQuestionState()) {
    on<SelectAnswer>((event, emit) {
      if (state.selectedAnswer != event.answerIndex) {
        emit(QuizQuestionState(selectedAnswer: event.answerIndex));
      }
    });
  }
}
