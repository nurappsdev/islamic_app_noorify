import 'package:dio/dio.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/network/dio_client.dart';
import 'package:tuhfatul_muslim/core/services/api_constants.dart';
import 'package:tuhfatul_muslim/core/utils/device_platform.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';

/// Registers/removes this device's FCM token against the backend so the
/// signed-in user can receive targeted push notifications. Throws
/// [ServerException] / [NetworkException]; never returns error states.
abstract interface class FcmTokenRemoteDataSource {
  Future<void> registerToken(String token);

  Future<void> removeToken(String token);
}

class FcmTokenRemoteDataSourceImpl implements FcmTokenRemoteDataSource {
  FcmTokenRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _dio = dio ?? DioClient().dio,
      _local = local ?? AuthLocalDataSourceImpl();

  final Dio _dio;
  final AuthLocalDataSource _local;

  @override
  Future<void> registerToken(String token) async {
    try {
      await _dio.post<dynamic>(
        ApiConstants.fcmTokenEndPoint,
        data: {'token': token, 'platform': devicePlatform},
        options: Options(headers: _authHeaders()),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> removeToken(String token) async {
    try {
      await _dio.delete<dynamic>(
        ApiConstants.fcmTokenEndPoint,
        data: {'token': token},
        options: Options(headers: _authHeaders()),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
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
          json['message']?.toString() ??
              'Request failed (${e.response?.statusCode ?? 'network error'}).',
          statusCode: e.response?.statusCode,
        );
    }
  }
}
