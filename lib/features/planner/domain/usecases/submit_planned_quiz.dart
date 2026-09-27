import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/repositories/quiz_plan_repository.dart';

class SubmitPlannedQuiz {
  const SubmitPlannedQuiz(this._repository);

  final QuizPlanRepository _repository;

  Future<Either<Failure, PlannedQuizResult>> call({
    required String planId,
    required String portionId,
    required PlannedQuizSubmission submission,
  }) => _repository.submitAttempt(
    planId: planId,
    portionId: portionId,
    submission: submission,
  );
}
