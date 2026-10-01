import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/planner/domain/entities/quiz_plan.dart';
import 'package:tuhfatul_muslim/features/planner/domain/repositories/quiz_plan_repository.dart';

class CreateQuizPlan {
  const CreateQuizPlan(this._repository);

  final QuizPlanRepository _repository;

  Future<Either<Failure, QuizPlan>> call(QuizPlanDraft draft) =>
      _repository.createPlan(draft);
}
