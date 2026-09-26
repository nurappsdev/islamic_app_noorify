import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';

/// Contract for the scheduled quiz plans. Every call returns [Right] with the
/// server's result or [Left] with a typed [Failure].
abstract interface class QuizPlanRepository {
  Future<Either<Failure, QuizPlan>> createPlan(QuizPlanDraft draft);

  Future<Either<Failure, QuizPlanPage>> getPlans({int page, int limit});

  Future<Either<Failure, QuizPlan>> getPlan(String planId);

  Future<Either<Failure, QuizPlan>> updatePlan(
    String planId,
    QuizPlanUpdate update,
  );

  /// Abandons the plan; the server keeps it, with status `abandoned`.
  Future<Either<Failure, QuizPlan>> abandonPlan(String planId);

  Future<Either<Failure, QuizPlan>> startPlan(String planId);

  Future<Either<Failure, PlannedQuestionPage>> getQuestions({
    required String planId,
    String? portionId,
    String? categoryId,
    int page,
    int limit,
  });

  Future<Either<Failure, PlannedQuizResult>> submitAttempt({
    required String planId,
    required String portionId,
    required PlannedQuizSubmission submission,
  });
}
