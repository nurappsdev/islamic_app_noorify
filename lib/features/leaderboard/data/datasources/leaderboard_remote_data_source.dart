import 'package:dio/dio.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/network/dio_client.dart';
import 'package:tuhfatul_muslim/core/services/api_constants.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/leaderboard/data/models/leaderboard_board_model.dart';
import 'package:tuhfatul_muslim/features/leaderboard/data/models/leaderboard_user_detail_model.dart';

/// Talks to the leaderboard REST endpoint. Throws [ServerException] /
/// [NetworkException] / [ParsingException]; never returns error states.
abstract interface class LeaderboardRemoteDataSource {
  /// `GET /leaderboard/top?period=daily|weekly|monthly|yearly&limit=N`.
  Future<LeaderboardBoardModel> getTop({
    required String period,
    required int limit,
  });

  /// `GET /leaderboard/users/:userId?period=...&date=...`. [date] is the
  /// period's `key` from a leaderboard response (`2026-09`); omitted, the
  /// server uses the current period.
  Future<LeaderboardUserDetailModel> getUserPosition({
    required String userId,
    required String period,
    String? date,
  });
}

class LeaderboardRemoteDataSourceImpl implements LeaderboardRemoteDataSource {
  LeaderboardRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _dio = dio ?? DioClient().dio,
      _local = local ?? AuthLocalDataSourceImpl();

  final Dio _dio;
  final AuthLocalDataSource _local;

  @override
  Future<LeaderboardBoardModel> getTop({
    required String period,
    required int limit,
  }) async => LeaderboardBoardModel.fromJson(
    await _getData(ApiConstants.leaderboardTopEndPoint, {
      'period': period,
      'limit': limit,
    }),
  );

  @override
  Future<LeaderboardUserDetailModel> getUserPosition({
    required String userId,
    required String period,
    String? date,
  }) async => LeaderboardUserDetailModel.fromJson(
    await _getData(ApiConstants.leaderboardUserEndPoint(userId), {
      'period': period,
      if (date != null && date.isNotEmpty) 'date': date,
    }),
  );

  /// GETs [path] and returns the envelope's `data` object.
  Future<Map<String, dynamic>> _getData(
    String path,
    Map<String, dynamic> query,
  ) async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: Options(headers: _authHeaders()),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final body = response.data;
    final json = body is Map<String, dynamic>
        ? body
        : const <String, dynamic>{};
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
      throw ParsingException('Leaderboard response is missing "data".');
    }
    return data;
  }

  Map<String, String>? _authHeaders() {
    final token = _local.getToken();
    return token == null ? null : {'Authorization': 'Bearer $token'};
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
