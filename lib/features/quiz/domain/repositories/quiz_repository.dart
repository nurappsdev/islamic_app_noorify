import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/daily_quiz_status.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_category.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';

/// Contract for the quiz API. Every call returns [Right] with the result or
/// [Left] with a typed [Failure].
abstract interface class QuizRepository {
  /// `GET /quizzes/categories` - active categories, in display order.
  Future<Either<Failure, List<QuizCategory>>> getCategories();

  /// `GET /quizzes/daily?date=YYYY-MM-DD`.
  Future<Either<Failure, Quiz>> getDailyQuiz(DateTime date);

  /// `GET /quizzes/daily/status`.
  Future<Either<Failure, DailyQuizStatus>> getDailyQuizStatus();

  /// `GET /quizzes/categories/{categoryId}/quiz?limit=N[&difficulty=..]`.
  Future<Either<Failure, Quiz>> getCategoryQuiz({
    required String categoryId,
    int limit,
    QuizDifficulty? difficulty,
  });

  /// `POST /quizzes/attempts` - scored by the server.
  Future<Either<Failure, QuizAttemptResult>> submitAttempt(
    QuizAttemptSubmission submission,
  );

  /// `GET /quizzes/attempts?page=N&limit=N[&attemptType=..]`.
  Future<Either<Failure, QuizAttemptPage>> getAttempts({
    int page,
    int limit,
    QuizAttemptType? attemptType,
  });

  /// `GET /quizzes/attempts/{attemptId}/review`.
  Future<Either<Failure, QuizAttemptDetail>> getAttemptReview(String attemptId);

  /// `GET /quizzes/dashboard`.
  Future<Either<Failure, QuizDashboardData>> getQuizDashboard(
    QuizDashboardFilter filter,
  );

  /// `GET /quizzes/dashboard/compare`.
  Future<Either<Failure, QuizComparison>> getQuizDashboardComparison(
    QuizComparisonFilter filter,
  );

  /// `GET /quizzes/dashboard/history/compare`.
  Future<Either<Failure, QuizComparison>> getQuizDashboardHistoryComparison(
    QuizComparisonFilter filter,
  );
}
