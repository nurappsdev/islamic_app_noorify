import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/usecases/get_quiz_attempt_detail.dart';

enum QuizAttemptReviewStatus { loading, success, failure }

class QuizAttemptReviewState {
  const QuizAttemptReviewState({
    this.status = QuizAttemptReviewStatus.loading,
    this.detail,
    this.errorMessage,
  });

  final QuizAttemptReviewStatus status;
  final QuizAttemptDetail? detail;
  final String? errorMessage;
}

abstract class QuizAttemptReviewEvent {
  const QuizAttemptReviewEvent();
}

/// Fetches the attempt; also used by Try Again.
class LoadQuizAttemptReview extends QuizAttemptReviewEvent {
  const LoadQuizAttemptReview();
}

/// One finished attempt with every answer revealed
/// (`GET /quizzes/attempts/{id}`).
class QuizAttemptReviewBloc
    extends Bloc<QuizAttemptReviewEvent, QuizAttemptReviewState> {
  QuizAttemptReviewBloc(this._getDetail, {required this.attemptId})
    : super(const QuizAttemptReviewState()) {
    on<LoadQuizAttemptReview>((event, emit) async {
      emit(const QuizAttemptReviewState());
      final result = await _getDetail(attemptId);
      result.fold(
        (failure) => emit(
          QuizAttemptReviewState(
            status: QuizAttemptReviewStatus.failure,
            errorMessage: failure.message,
          ),
        ),
        (detail) => emit(
          QuizAttemptReviewState(
            status: QuizAttemptReviewStatus.success,
            detail: detail,
          ),
        ),
      );
    });
  }

  final GetQuizAttemptDetail _getDetail;
  final String attemptId;
}
