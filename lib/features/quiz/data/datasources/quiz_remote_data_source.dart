import 'package:dio/dio.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/network/dio_client.dart';
import 'package:tuhfatul_muslim/core/services/api_constants.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/quiz/data/datasources/quiz_api_requests.dart';
import 'package:tuhfatul_muslim/features/quiz/data/models/daily_quiz_status_model.dart';
import 'package:tuhfatul_muslim/features/quiz/data/models/quiz_attempt_model.dart';
import 'package:tuhfatul_muslim/features/quiz/data/models/quiz_category_model.dart';
import 'package:tuhfatul_muslim/features/quiz/data/models/quiz_dashboard_model.dart';
import 'package:tuhfatul_muslim/features/quiz/data/models/quiz_model.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_enums.dart';

/// Talks to the quiz REST endpoints. Throws [ServerException] /
/// [NetworkException] / [ParsingException]; never returns error states.
abstract interface class QuizRemoteDataSource {
  /// `GET /quizzes/categories` (public).
  Future<List<QuizCategoryModel>> getCategories();

  /// `GET /quizzes/daily?date=YYYY-MM-DD`.
  Future<QuizModel> getDailyQuiz(DateTime date);

  /// `GET /quizzes/daily/status`.
  Future<DailyQuizStatusModel> getDailyQuizStatus();

  /// `GET /quizzes/categories/{categoryId}/quiz?limit=N[&difficulty=..]`.
  Future<QuizModel> getCategoryQuiz({
    required String categoryId,
    required int limit,
    QuizDifficulty? difficulty,
  });

  /// `POST /quizzes/attempts`.
  Future<QuizAttemptResultModel> submitAttempt(
    QuizAttemptSubmission submission,
  );

  /// `GET /quizzes/attempts?page=N&limit=N[&attemptType=..]`.
  Future<QuizAttemptPageModel> getAttempts({
    required int page,
    required int limit,
    QuizAttemptType? attemptType,
  });

  /// `GET /quizzes/attempts/{attemptId}/review`.
  Future<QuizAttemptDetailModel> getAttemptReview(String attemptId);

  /// `GET /quizzes/dashboard`.
  Future<QuizDashboardDataModel> getDashboard(QuizDashboardFilter filter);

  /// `GET /quizzes/dashboard/compare`.
  Future<QuizComparisonModel> getDashboardComparison(
    QuizComparisonFilter filter,
  );

  /// `GET /quizzes/dashboard/history/compare`.
  Future<QuizComparisonModel> getDashboardHistoryComparison(
    QuizComparisonFilter filter,
  );
}

class QuizRemoteDataSourceImpl
    with QuizApiRequests
    implements QuizRemoteDataSource {
  QuizRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : dio = dio ?? DioClient().dio,
      local = local ?? AuthLocalDataSourceImpl();

  @override
  final Dio dio;
  @override
  final AuthLocalDataSource local;

  @override
  Future<List<QuizCategoryModel>> getCategories() async {
    final json = await sendQuizRequest(
      () => dio.get<dynamic>(ApiConstants.quizCategoriesEndPoint),
    );
    final data = json['data'];
    if (data is! List) {
      throw ParsingException('Quiz categories response is missing "data".');
    }
    final categories =
        data
            .map(readMap)
            .whereType<Map<String, dynamic>>()
            .map(QuizCategoryModel.fromJson)
            .where((category) => category.id.isNotEmpty && category.isActive)
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return categories;
  }

  @override
  Future<QuizModel> getDailyQuiz(DateTime date) async {
    final json = await sendQuizRequest(
      () => dio.get<dynamic>(
        ApiConstants.quizDailyEndPoint,
        queryParameters: {'date': formatQuizDate(date)},
        options: quizAuthOptions(),
      ),
    );
    return QuizModel.fromJson(quizDataMap(json, 'Daily quiz'));
  }

  @override
  Future<DailyQuizStatusModel> getDailyQuizStatus() async {
    final token = local.getToken();
    if (token == null) {
      return DailyQuizStatusModel(
        date: formatQuizDate(DateTime.now()),
        isAvailable: true,
        isCompleted: false,
        hasCompleted: false,
      );
    }
    final json = await sendQuizRequest(
      () => dio.get<dynamic>(
        ApiConstants.quizDailyStatusEndPoint,
        options: quizAuthOptions(),
      ),
    );
    return DailyQuizStatusModel.fromJson(
      quizDataMap(json, 'Daily quiz status'),
    );
  }

  @override
  Future<QuizModel> getCategoryQuiz({
    required String categoryId,
    required int limit,
    QuizDifficulty? difficulty,
  }) async {
    final json = await sendQuizRequest(
      () => dio.get<dynamic>(
        ApiConstants.quizCategoryQuizEndPoint(categoryId),
        queryParameters: {
          'limit': limit,
          if (difficulty != null) 'difficulty': difficulty.apiValue,
        },
        options: quizAuthOptions(),
      ),
    );
    return QuizModel.fromJson(quizDataMap(json, 'Category quiz'));
  }

  @override
  Future<QuizAttemptResultModel> submitAttempt(
    QuizAttemptSubmission submission,
  ) async {
    final json = await sendQuizRequest(
      () => dio.post<dynamic>(
        ApiConstants.quizAttemptsEndPoint,
        data: submission.toJson(),
        options: quizAuthOptions(),
      ),
    );
    return QuizAttemptResultModel.fromJson(quizDataMap(json, 'Quiz attempt'));
  }

  @override
  Future<QuizAttemptPageModel> getAttempts({
    required int page,
    required int limit,
    QuizAttemptType? attemptType,
  }) async {
    final json = await sendQuizRequest(
      () => dio.get<dynamic>(
        ApiConstants.quizAttemptsEndPoint,
        queryParameters: {
          if (attemptType != null) 'attemptType': attemptType.apiValue,
          'page': page,
          'limit': limit,
        },
        options: quizAuthOptions(),
      ),
    );
    return QuizAttemptPageModel.fromJson(
      quizDataMap(json, 'Quiz attempts'),
      readMap(json['meta']),
    );
  }

  @override
  Future<QuizAttemptDetailModel> getAttemptReview(String attemptId) async {
    final json = await sendQuizRequest(
      () => dio.get<dynamic>(
        ApiConstants.quizAttemptReviewEndPoint(attemptId),
        options: quizAuthOptions(),
      ),
    );
    return QuizAttemptDetailModel.fromJson(quizDataMap(json, 'Quiz attempt'));
  }

  @override
  Future<QuizDashboardDataModel> getDashboard(
    QuizDashboardFilter filter,
  ) async {
    final json = await sendQuizRequest(
      () => dio.get<dynamic>(
        ApiConstants.quizDashboardEndPoint,
        queryParameters: quizDashboardQuery(filter),
        options: quizAuthOptions(),
      ),
    );
    return QuizDashboardDataModel.fromJson(
      quizDataMap(json, 'Quiz dashboard'),
      meta: json['meta'],
    );
  }

  @override
  Future<QuizComparisonModel> getDashboardComparison(
    QuizComparisonFilter filter,
  ) => _getComparison(ApiConstants.quizDashboardCompareEndPoint, filter);

  @override
  Future<QuizComparisonModel> getDashboardHistoryComparison(
    QuizComparisonFilter filter,
  ) => _getComparison(ApiConstants.quizDashboardHistoryCompareEndPoint, filter);

  Future<QuizComparisonModel> _getComparison(
    String path,
    QuizComparisonFilter filter,
  ) async {
    final json = await sendQuizRequest(
      () => dio.get<dynamic>(
        path,
        queryParameters: quizDashboardQuery(filter),
        options: quizAuthOptions(),
      ),
    );
    return QuizComparisonModel.fromJson(
      quizDataMap(json, 'Quiz comparison'),
      meta: json['meta'],
    );
  }
}

/// The query for the dashboard and compare endpoints: only the fields that
/// are set, dates as `YYYY-MM-DD`.
Map<String, Object> quizDashboardQuery(QuizDashboardFilter filter) {
  final days = filter.days;
  final from = filter.from;
  final to = filter.to;
  return {
    'period': filter.period.apiValue,
    'days': ?days,
    if (from != null) 'from': formatQuizDate(from),
    if (to != null) 'to': formatQuizDate(to),
    'page': filter.page,
    'limit': filter.limit,
  };
}

/// [date]'s local calendar day as `YYYY-MM-DD`, the format the API expects.
String formatQuizDate(DateTime date) {
  final local = date.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
