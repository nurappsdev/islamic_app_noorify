import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/planner/domain/entities/quiz_plan.dart';
import 'package:tuhfatul_muslim/features/planner/domain/repositories/quiz_plan_repository.dart';

class AbandonQuizPlan {
  const AbandonQuizPlan(this._repository);

  final QuizPlanRepository _repository;

  Future<Either<Failure, QuizPlan>> call(String planId) =>
      _repository.abandonPlan(planId);
}
