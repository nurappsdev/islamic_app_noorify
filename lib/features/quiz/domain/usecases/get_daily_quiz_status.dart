import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/daily_quiz_status.dart';
import 'package:islami_app_noorify/features/quiz/domain/repositories/quiz_repository.dart';

class GetDailyQuizStatus {
  const GetDailyQuizStatus(this._repository);

  final QuizRepository _repository;

  Future<Either<Failure, DailyQuizStatus>> call() =>
      _repository.getDailyQuizStatus();
}
