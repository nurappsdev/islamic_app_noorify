import 'package:dio/dio.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/network/dio_client.dart';
import 'package:islami_app_noorify/core/services/api_constants.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/quiz/data/models/quiz_attempt_model.dart';
import 'package:islami_app_noorify/features/quiz/data/models/quiz_category_model.dart';
import 'package:islami_app_noorify/features/quiz/data/models/quiz_model.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';

/// Talks to the quiz REST endpoints. Throws [ServerException] /
/// [NetworkException] / [ParsingException]; never returns error states.
abstract interface class QuizRemoteDataSource {
  /// `GET /quizzes/categories` (public).
  Future<List<QuizCategoryModel>> getCategories();

  /// `GET /quizzes/daily?date=YYYY-MM-DD`.
  Future<QuizModel> getDailyQuiz(DateTime date);

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

  /// `GET /quizzes/attempts/{attemptId}`.
  Future<QuizAttemptDetailModel> getAttemptDetail(String attemptId);
}

class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  QuizRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _dio = dio ?? DioClient().dio,
      _local = local ?? AuthLocalDataSourceImpl();

  final Dio _dio;
  final AuthLocalDataSource _local;

  @override
  Future<List<QuizCategoryModel>> getCategories() async {
    final json = await _send(
      () => _dio.get<dynamic>(ApiConstants.quizCategoriesEndPoint),
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
    final json = await _send(
      () => _dio.get<dynamic>(
        ApiConstants.quizDailyEndPoint,
        queryParameters: {'date': formatQuizDate(date)},
        options: _authOptions(),
      ),
    );
    return QuizModel.fromJson(_dataMap(json, 'Daily quiz'));
  }

  @override
  Future<QuizModel> getCategoryQuiz({
    required String categoryId,
    required int limit,
    QuizDifficulty? difficulty,
  }) async {
    final json = await _send(
      () => _dio.get<dynamic>(
        ApiConstants.quizCategoryQuizEndPoint(categoryId),
        queryParameters: {
          'limit': limit,
          if (difficulty != null) 'difficulty': difficulty.apiValue,
        },
        options: _authOptions(),
      ),
    );
    return QuizModel.fromJson(_dataMap(json, 'Category quiz'));
  }

  @override
  Future<QuizAttemptResultModel> submitAttempt(
    QuizAttemptSubmission submission,
  ) async {
    final json = await _send(
      () => _dio.post<dynamic>(
        ApiConstants.quizAttemptsEndPoint,
        data: submission.toJson(),
        options: _authOptions(),
      ),
    );
    return QuizAttemptResultModel.fromJson(_dataMap(json, 'Quiz attempt'));
  }

  @override
  Future<QuizAttemptPageModel> getAttempts({
    required int page,
    required int limit,
    QuizAttemptType? attemptType,
  }) async {
    final json = await _send(
      () => _dio.get<dynamic>(
        ApiConstants.quizAttemptsEndPoint,
        queryParameters: {
          if (attemptType != null) 'attemptType': attemptType.apiValue,
          'page': page,
          'limit': limit,
        },
        options: _authOptions(),
      ),
    );
    return QuizAttemptPageModel.fromJson(
      _dataMap(json, 'Quiz attempts'),
      readMap(json['meta']),
    );
  }

  @override
  Future<QuizAttemptDetailModel> getAttemptDetail(String attemptId) async {
    final json = await _send(
      () => _dio.get<dynamic>(
        ApiConstants.quizAttemptEndPoint(attemptId),
        options: _authOptions(),
      ),
    );
    return QuizAttemptDetailModel.fromJson(_dataMap(json, 'Quiz attempt'));
  }

  /// Runs [request] and returns its JSON envelope, or throws when the call
  /// failed or the server answered with an error.
  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    final Response<dynamic> response;
    try {
      response = await request();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final json = readMap(response.data) ?? const <String, dynamic>{};
    final status = response.statusCode ?? 0;
    final isSuccess = status >= 200 && status < 300 && json['success'] != false;
    if (!isSuccess) {
      throw ServerException(
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }
    return json;
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> json, String what) {
    final data = readMap(json['data']);
    if (data == null) {
      throw ParsingException('$what response is missing "data".');
    }
    return data;
  }

  Options _authOptions() {
    final token = _local.getToken();
    return Options(
      headers: token == null ? null : {'Authorization': 'Bearer $token'},
    );
  }

  /// Turns a low-level [DioException] into one of our data-layer exceptions.
  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return NetworkException('The request timed out. Please try again.');
      case DioExceptionType.connectionError:
        return NetworkException();
      case DioExceptionType.badCertificate:
        return NetworkException('Could not establish a secure connection.');
      case DioExceptionType.cancel:
        return NetworkException('The request was cancelled.');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final json = readMap(e.response?.data) ?? const <String, dynamic>{};
        return ServerException(
          _extractError(json) ??
              'Request failed (${e.response?.statusCode ?? 'network error'}).',
          statusCode: e.response?.statusCode,
        );
    }
  }

  /// Reads a message out of `{ errorSources: [{message}], message }`.
  String? _extractError(Map<String, dynamic> json) {
    final sources = json['errorSources'];
    if (sources is List && sources.isNotEmpty) {
      final messages = sources
          .whereType<Map>()
          .map((e) => e['message']?.toString())
          .where((m) => m != null && m.isNotEmpty)
          .join('\n');
      if (messages.isNotEmpty) return messages;
    }
    final message = json['message']?.toString();
    return (message != null && message.isNotEmpty) ? message : null;
  }
}

/// [date]'s local calendar day as `YYYY-MM-DD`, the format the API expects.
String formatQuizDate(DateTime date) {
  final local = date.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
