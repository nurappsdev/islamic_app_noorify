import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/repositories/quiz_repository.dart';

class GetQuizDashboardHistoryComparison {
  const GetQuizDashboardHistoryComparison(this._repository);

  final QuizRepository _repository;

  Future<Either<Failure, QuizComparison>> call(QuizComparisonFilter filter) =>
      _repository.getQuizDashboardHistoryComparison(filter);
}
