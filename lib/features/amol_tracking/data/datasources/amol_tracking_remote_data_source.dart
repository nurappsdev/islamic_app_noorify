import 'package:dio/dio.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/network/dio_client.dart';
import 'package:islami_app_noorify/core/services/api_constants.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/amol_tracking/data/models/amol_daily_dashboard_model.dart';

/// Talks to the Amol Tracking REST endpoints. Throws [ServerException] /
/// [NetworkException] / [ParsingException]; never returns error states.
abstract interface class AmolTrackingRemoteDataSource {
  /// `GET /amol/tracker/daily?date=YYYY-MM-DD`.
  Future<AmolDailyDashboardModel> getDaily({required String date});

  /// `POST /amol/tracker/log-item`. Returns the day's updated dashboard
  /// (same shape as [getDaily]) so the caller can refresh from one response.
  Future<AmolDailyDashboardModel> logItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  });

  /// `DELETE /amol/tracker/delete-item`. Un-checks a previously logged item;
  /// returns the day's updated dashboard (same shape as [getDaily]).
  Future<AmolDailyDashboardModel> deleteItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  });
}

class AmolTrackingRemoteDataSourceImpl implements AmolTrackingRemoteDataSource {
  AmolTrackingRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _dio = dio ?? DioClient().dio,
      _local = local ?? AuthLocalDataSourceImpl();

  final Dio _dio;
  final AuthLocalDataSource _local;

  @override
  Future<AmolDailyDashboardModel> getDaily({required String date}) async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        ApiConstants.amolTrackerDailyEndPoint,
        queryParameters: {'date': date},
        options: Options(headers: _authHeaders()),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
    return _parseDashboard(response);
  }

  @override
  Future<AmolDailyDashboardModel> logItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        ApiConstants.amolTrackerLogItemEndPoint,
        data: {'logDate': logDate, 'pillarKey': pillarKey, 'itemKey': itemKey},
        options: Options(headers: _authHeaders()),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
    return _parseDashboard(response);
  }

  @override
  Future<AmolDailyDashboardModel> deleteItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.delete<dynamic>(
        ApiConstants.amolTrackerDeleteItemEndPoint,
        data: {'logDate': logDate, 'pillarKey': pillarKey, 'itemKey': itemKey},
        options: Options(headers: _authHeaders()),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
    return _parseDashboard(response);
  }

  Map<String, String>? _authHeaders() {
    final token = _local.getToken();
    return token == null ? null : {'Authorization': 'Bearer $token'};
  }

  /// Both endpoints return the same `{ ..., data: <dashboard> }` envelope.
  AmolDailyDashboardModel _parseDashboard(Response<dynamic> response) {
    final body = response.data;
    final json = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    final status = response.statusCode ?? 0;
    final isSuccess = status >= 200 && status < 300 && json['success'] != false;
    if (!isSuccess) {
      throw ServerException(
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }

    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw ParsingException('Amol response is missing "data".');
    }
    return AmolDailyDashboardModel.fromJson(data);
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
        final data = e.response?.data;
        final json =
            data is Map<String, dynamic> ? data : const <String, dynamic>{};
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
