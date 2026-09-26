import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';
import 'package:islami_app_noorify/features/quiz/domain/repositories/quiz_repository.dart';

class GetQuizAttempts {
  const GetQuizAttempts(this._repository);

  final QuizRepository _repository;

  Future<Either<Failure, QuizAttemptPage>> call({
    int page = 1,
    int limit = 10,
    QuizAttemptType? attemptType,
  }) => _repository.getAttempts(
    page: page,
    limit: limit,
    attemptType: attemptType,
  );
}
