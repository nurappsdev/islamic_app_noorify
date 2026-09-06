import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:islami_app_noorify/core/services/api_constants.dart';

/// Single configured [Dio] instance used by every remote data source.
///
/// Usage:
/// ```dart
/// final client = DioClient();
/// final response = await client.dio.post(ApiConstants.signUpEndPoint, data: {...});
/// ```
class DioClient {
  DioClient({Dio? dio}) : dio = dio ?? _build();

  final Dio dio;

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        headers: {'Accept': 'application/json'},
        // Let us inspect the body of 4xx/5xx responses instead of throwing
        // before we can read the API error envelope.
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }

    return dio;
  }
}
