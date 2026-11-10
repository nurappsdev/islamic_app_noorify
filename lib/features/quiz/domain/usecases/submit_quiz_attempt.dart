import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/repositories/quiz_repository.dart';

class SubmitQuizAttempt {
  const SubmitQuizAttempt(this._repository);

  final QuizRepository _repository;

  Future<Either<Failure, QuizAttemptResult>> call(
    QuizAttemptSubmission submission,
  ) => _repository.submitAttempt(submission);
}
