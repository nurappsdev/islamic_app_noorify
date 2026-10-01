import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_enums.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/repositories/quiz_repository.dart';

class GetCategoryQuiz {
  const GetCategoryQuiz(this._repository);

  final QuizRepository _repository;

  Future<Either<Failure, Quiz>> call({
    required String categoryId,
    int limit = 10,
    QuizDifficulty? difficulty,
  }) => _repository.getCategoryQuiz(
    categoryId: categoryId,
    limit: limit,
    difficulty: difficulty,
  );
}
