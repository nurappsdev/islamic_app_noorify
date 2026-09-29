import 'package:dio/dio.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/network/dio_client.dart';
import 'package:tuhfatul_muslim/core/services/api_constants.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_plan.dart';

abstract interface class QuranPlanRemoteDataSource {
  /// `POST /quran/plans`: creates a new Quran plan.
  Future<QuranPlan> createPlan(CreateQuranPlanRequest request);

  /// `GET /quran/plans?status={status}&page={page}&limit={limit}`:
  /// retrieves user's Quran plans.
  Future<QuranPlansResponse> getPlans({
    String? status,
    int page = 1,
    int limit = 10,
  });

  /// `GET /quran/plans/{planId}`: retrieves details of a specific plan.
  Future<QuranPlan> getPlanDetails(String planId);

  /// `PATCH /quran/plans/{planId}`: updates a Quran plan.
  Future<QuranPlan> updatePlan(String planId, UpdateQuranPlanRequest request);

  /// `PATCH /quran/plans/{planId}/complete`: marks a plan completed if all ayahs are read.
  Future<QuranPlan> completePlan(String planId);

  /// `GET /quran/plans/{planId}/ayahs?filter={filter}&page={page}&limit={limit}`:
  /// retrieves paginated list of ayahs in the plan.
  Future<PaginatedQuranPlanAyahs> getPlanAyahs(
    String planId, {
    String filter = 'all',
    int page = 1,
    int limit = 10,
  });

  /// `DELETE /quran/plans/{planId}`: deletes/deactivates a Quran plan.
  Future<void> deletePlan(String planId);
}

class QuranPlanRemoteDataSourceImpl implements QuranPlanRemoteDataSource {
  QuranPlanRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _dioOverride = dio,
      _localOverride = local;

  final Dio? _dioOverride;
  final AuthLocalDataSource? _localOverride;

  late final Dio _dio = _dioOverride ?? DioClient().dio;
  late final AuthLocalDataSource _local =
      _localOverride ?? AuthLocalDataSourceImpl();

  @override
  Future<QuranPlan> createPlan(CreateQuranPlanRequest request) async {
    final data = await _sendAuthed(
      'POST',
      ApiConstants.quranPlansEndPoint,
      data: request.toJson(),
      what: 'Create Quran plan',
    );
    if (data is! Map<String, dynamic>) {
      throw ParsingException('Create Quran plan response is missing "data".');
    }
    return QuranPlan.fromJson(data);
  }

  @override
  Future<QuranPlansResponse> getPlans({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    final json = await _getEnvelope(ApiConstants.quranPlansEndPoint, {
      if (status != null && status.isNotEmpty) 'status': status,
      'page': page,
      'limit': limit,
    }, 'Quran plans');
    return QuranPlansResponse.fromJson(json);
  }

  @override
  Future<QuranPlan> getPlanDetails(String planId) async {
    final data = await _sendAuthed(
      'GET',
      ApiConstants.quranPlanEndPoint(planId),
      what: 'Get Quran plan details',
    );
    if (data is! Map<String, dynamic>) {
      throw ParsingException(
        'Get Quran plan details response is missing "data".',
      );
    }
    return QuranPlan.fromJson(data);
  }

  @override
  Future<QuranPlan> updatePlan(
    String planId,
    UpdateQuranPlanRequest request,
  ) async {
    final data = await _sendAuthed(
      'PATCH',
      ApiConstants.quranPlanEndPoint(planId),
      data: request.toJson(),
      what: 'Update Quran plan',
    );
    if (data is! Map<String, dynamic>) {
      throw ParsingException('Update Quran plan response is missing "data".');
    }
    return QuranPlan.fromJson(data);
  }

  @override
  Future<QuranPlan> completePlan(String planId) async {
    final data = await _sendAuthed(
      'PATCH',
      ApiConstants.quranPlanCompleteEndPoint(planId),
      what: 'Complete Quran plan',
    );
    if (data is! Map<String, dynamic>) {
      throw ParsingException('Complete Quran plan response is missing "data".');
    }
    return QuranPlan.fromJson(data);
  }

  @override
  Future<PaginatedQuranPlanAyahs> getPlanAyahs(
    String planId, {
    String filter = 'all',
    int page = 1,
    int limit = 10,
  }) async {
    final json = await _getEnvelope(
      ApiConstants.quranPlanAyahsEndPoint(planId),
      {'filter': filter, 'page': page, 'limit': limit},
      'Quran plan ayahs',
    );
    return PaginatedQuranPlanAyahs.fromJson(json);
  }

  @override
  Future<void> deletePlan(String planId) async {
    await _sendAuthed(
      'DELETE',
      ApiConstants.quranPlanEndPoint(planId),
      what: 'Delete Quran plan',
    );
  }

  Future<dynamic> _sendAuthed(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    required String what,
  }) async {
    final token = _local.getToken();
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final raw = response.data;
    final json = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final status = response.statusCode ?? 0;
    final isSuccess = status >= 200 && status < 300 && json['success'] != false;
    if (!isSuccess) {
      throw ServerException(
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }
    return json['data'];
  }

  Future<Map<String, dynamic>> _getEnvelope(
    String path,
    Map<String, dynamic> query,
    String what,
  ) async {
    final token = _local.getToken();
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: Options(
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final raw = response.data;
    final json = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
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
        final data = e.response?.data;
        final json = data is Map<String, dynamic>
            ? data
            : const <String, dynamic>{};
        return ServerException(
          _extractError(json) ??
              'Request failed (${e.response?.statusCode ?? 'network error'}).',
          statusCode: e.response?.statusCode,
        );
    }
  }

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
