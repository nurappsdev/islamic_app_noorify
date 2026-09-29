import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/repositories/quiz_repository.dart';

class GetQuizDashboardComparison {
  const GetQuizDashboardComparison(this._repository);

  final QuizRepository _repository;

  Future<Either<Failure, QuizComparison>> call(QuizComparisonFilter filter) =>
      _repository.getQuizDashboardComparison(filter);
}
