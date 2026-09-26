import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/repositories/quiz_repository.dart';

class GetQuizAttemptReview {
  const GetQuizAttemptReview(this._repository);

  final QuizRepository _repository;

  Future<Either<Failure, QuizAttemptDetail>> call(String attemptId) =>
      _repository.getAttemptReview(attemptId);
}
