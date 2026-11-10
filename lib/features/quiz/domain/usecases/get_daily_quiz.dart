import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/repositories/quiz_repository.dart';

class GetDailyQuiz {
  const GetDailyQuiz(this._repository);

  final QuizRepository _repository;

  /// The quiz for the device's local calendar day of [date].
  Future<Either<Failure, Quiz>> call(DateTime date) =>
      _repository.getDailyQuiz(date);
}
