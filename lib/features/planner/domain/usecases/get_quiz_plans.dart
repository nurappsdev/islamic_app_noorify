import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/planner/domain/entities/quiz_plan.dart';
import 'package:tuhfatul_muslim/features/planner/domain/repositories/quiz_plan_repository.dart';

class GetQuizPlans {
  const GetQuizPlans(this._repository);

  final QuizPlanRepository _repository;

  Future<Either<Failure, QuizPlanPage>> call({int page = 1, int limit = 10}) =>
      _repository.getPlans(page: page, limit: limit);
}
