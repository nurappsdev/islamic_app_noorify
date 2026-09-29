import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';

import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/get_quiz_attempt_review.dart';

enum QuizAttemptReviewStatus { loading, success, failure }

class QuizAttemptReviewState {
  const QuizAttemptReviewState({
    this.status = QuizAttemptReviewStatus.loading,
    this.detail,
    this.failure,
  });

  final QuizAttemptReviewStatus status;
  final QuizAttemptDetail? detail;
  final Failure? failure;
}

abstract class QuizAttemptReviewEvent {
  const QuizAttemptReviewEvent();
}

/// Fetches the attempt; also used by Try Again.
class LoadQuizAttemptReview extends QuizAttemptReviewEvent {
  const LoadQuizAttemptReview();
}

/// One finished attempt with every answer revealed and grouped
/// (`GET /quizzes/attempts/{id}/review`).
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
            failure: failure,
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

  final GetQuizAttemptReview _getDetail;
  final String attemptId;
}
