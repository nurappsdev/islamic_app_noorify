import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:islami_app_noorify/features/quiz/domain/repositories/quiz_repository.dart';

class GetQuizDashboard {
  const GetQuizDashboard(this._repository);

  final QuizRepository _repository;

  Future<Either<Failure, QuizDashboardData>> call(QuizDashboardFilter filter) =>
      _repository.getQuizDashboard(filter);
}
