import 'package:bloc/bloc.dart';
import 'package:islami_app_noorify/features/quiz/domain/usecases/get_completed_quiz_history.dart';

import 'quiz_state.dart';

export 'quiz_state.dart';

class QuizCubit extends Cubit<QuizState> {
  QuizCubit(this._getCompletedQuizHistory) : super(const QuizState());

  final GetCompletedQuizHistory _getCompletedQuizHistory;

  Future<void> loadCompletedQuizHistory() async {
    emit(const QuizState(status: QuizStatus.loading));

    try {
      final history = await _getCompletedQuizHistory();
      emit(QuizState(status: QuizStatus.success, completedHistory: history));
    } catch (_) {
      emit(const QuizState(status: QuizStatus.failure));
    }
  }
}
