import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/daily_quiz_status.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_category.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';
import 'package:islami_app_noorify/features/quiz/domain/repositories/quiz_repository.dart';

class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl(this._remote);

  final QuizRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<QuizCategory>>> getCategories() =>
      _guard(_remote.getCategories);

  @override
  Future<Either<Failure, Quiz>> getDailyQuiz(DateTime date) =>
      _guard(() => _remote.getDailyQuiz(date));

  @override
  Future<Either<Failure, DailyQuizStatus>> getDailyQuizStatus() =>
      _guard(_remote.getDailyQuizStatus);

  @override
  Future<Either<Failure, Quiz>> getCategoryQuiz({
    required String categoryId,
    int limit = 10,
    QuizDifficulty? difficulty,
  }) => _guard(
    () => _remote.getCategoryQuiz(
      categoryId: categoryId,
      limit: limit,
      difficulty: difficulty,
    ),
  );

  @override
  Future<Either<Failure, QuizAttemptResult>> submitAttempt(
    QuizAttemptSubmission submission,
  ) => _guard(() => _remote.submitAttempt(submission));

  @override
  Future<Either<Failure, QuizAttemptPage>> getAttempts({
    int page = 1,
    int limit = 10,
    QuizAttemptType? attemptType,
  }) => _guard(
    () =>
        _remote.getAttempts(page: page, limit: limit, attemptType: attemptType),
  );

  @override
  Future<Either<Failure, QuizAttemptDetail>> getAttemptReview(
    String attemptId,
  ) => _guard(() => _remote.getAttemptReview(attemptId));

  @override
  Future<Either<Failure, QuizDashboardData>> getQuizDashboard(
    QuizDashboardFilter filter,
  ) => _guard(() => _remote.getDashboard(filter));

  @override
  Future<Either<Failure, QuizComparison>> getQuizDashboardComparison(
    QuizComparisonFilter filter,
  ) => _guard(() => _remote.getDashboardComparison(filter));

  @override
  Future<Either<Failure, QuizComparison>> getQuizDashboardHistoryComparison(
    QuizComparisonFilter filter,
  ) => _guard(() => _remote.getDashboardHistoryComparison(filter));

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
