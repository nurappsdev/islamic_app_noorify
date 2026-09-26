import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/planner/data/datasources/quiz_plan_remote_data_source.dart';
import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/repositories/quiz_plan_repository.dart';

class QuizPlanRepositoryImpl implements QuizPlanRepository {
  QuizPlanRepositoryImpl(this._remote);

  final QuizPlanRemoteDataSource _remote;

  @override
  Future<Either<Failure, QuizPlan>> createPlan(QuizPlanDraft draft) =>
      _guard(() => _remote.createPlan(draft));

  @override
  Future<Either<Failure, QuizPlanPage>> getPlans({
    int page = 1,
    int limit = 10,
  }) => _guard(() => _remote.getPlans(page: page, limit: limit));

  @override
  Future<Either<Failure, QuizPlan>> getPlan(String planId) =>
      _guard(() => _remote.getPlan(planId));

  @override
  Future<Either<Failure, QuizPlan>> updatePlan(
    String planId,
    QuizPlanUpdate update,
  ) => _guard(() => _remote.updatePlan(planId, update));

  @override
  Future<Either<Failure, QuizPlan>> abandonPlan(String planId) =>
      _guard(() => _remote.abandonPlan(planId));

  @override
  Future<Either<Failure, QuizPlan>> startPlan(String planId) =>
      _guard(() => _remote.startPlan(planId));

  @override
  Future<Either<Failure, PlannedQuestionPage>> getQuestions({
    required String planId,
    String? portionId,
    String? categoryId,
    int page = 1,
    int limit = 10,
  }) => _guard(
    () => _remote.getQuestions(
      planId: planId,
      portionId: portionId,
      categoryId: categoryId,
      page: page,
      limit: limit,
    ),
  );

  @override
  Future<Either<Failure, PlannedQuizResult>> submitAttempt({
    required String planId,
    required String portionId,
    required PlannedQuizSubmission submission,
  }) => _guard(
    () => _remote.submitAttempt(
      planId: planId,
      portionId: portionId,
      submission: submission,
    ),
  );

  /// Keeps the server's message on the failure, for debugging; the screens
  /// show a localized message chosen from the failure's kind instead.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
