import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';
import 'package:islami_app_noorify/features/quiz/domain/usecases/get_quiz_attempts.dart';

import 'quiz_event.dart';
import 'quiz_state.dart';

export 'quiz_event.dart';
export 'quiz_state.dart';

/// The user's quiz attempt history (`GET /quizzes/attempts`), page by page.
class QuizBloc extends Bloc<QuizEvent, QuizState> {
  QuizBloc(this._getAttempts, {this.pageSize = 10, this.attemptType})
    : super(const QuizState()) {
    on<LoadCompletedQuizHistory>((event, emit) async {
      emit(const QuizState(status: QuizStatus.loading));
      final result = await _getAttempts(
        page: 1,
        limit: pageSize,
        attemptType: attemptType,
      );
      result.fold(
        (failure) =>
            emit(QuizState(status: QuizStatus.failure, failure: failure)),
        (page) => emit(
          QuizState(
            status: QuizStatus.success,
            attempts: page.attempts,
            summary: page.summary,
            page: page.page,
            hasMore: page.hasMore,
          ),
        ),
      );
    });

    on<LoadMoreQuizHistory>((event, emit) async {
      if (state.status != QuizStatus.success ||
          !state.hasMore ||
          state.isLoadingMore) {
        return;
      }
      emit(state.copyWith(isLoadingMore: true));
      final result = await _getAttempts(
        page: state.page + 1,
        limit: pageSize,
        attemptType: attemptType,
      );
      result.fold(
        // The rows already shown stay; scrolling to the end again retries.
        (_) => emit(state.copyWith(isLoadingMore: false)),
        (page) => emit(
          state.copyWith(
            attempts: [...state.attempts, ...page.attempts],
            page: page.page,
            hasMore: page.hasMore,
            isLoadingMore: false,
          ),
        ),
      );
    });
  }

  final GetQuizAttempts _getAttempts;
  final int pageSize;

  /// Restricts the history to one kind of attempt; `null` shows all.
  final QuizAttemptType? attemptType;
}
