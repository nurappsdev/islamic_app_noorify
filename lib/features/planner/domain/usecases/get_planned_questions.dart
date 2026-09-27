import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/repositories/quiz_plan_repository.dart';

class GetPlannedQuestions {
  const GetPlannedQuestions(this._repository);

  final QuizPlanRepository _repository;

  Future<Either<Failure, PlannedQuestionPage>> call({
    required String planId,
    String? portionId,
    String? categoryId,
    int page = 1,
    int limit = 10,
  }) => _repository.getQuestions(
    planId: planId,
    portionId: portionId,
    categoryId: categoryId,
    page: page,
    limit: limit,
  );
}
