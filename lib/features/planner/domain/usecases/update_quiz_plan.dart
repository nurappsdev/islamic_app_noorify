import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/planner/domain/entities/quiz_plan.dart';
import 'package:tuhfatul_muslim/features/planner/domain/repositories/quiz_plan_repository.dart';

class UpdateQuizPlan {
  const UpdateQuizPlan(this._repository);

  final QuizPlanRepository _repository;

  Future<Either<Failure, QuizPlan>> call(
    String planId,
    QuizPlanUpdate update,
  ) => _repository.updatePlan(planId, update);
}
