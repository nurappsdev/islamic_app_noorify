import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_category.dart';
import 'package:islami_app_noorify/features/quiz/domain/repositories/quiz_repository.dart';

class GetQuizCategories {
  const GetQuizCategories(this._repository);

  final QuizRepository _repository;

  Future<Either<Failure, List<QuizCategory>>> call() =>
      _repository.getCategories();
}
