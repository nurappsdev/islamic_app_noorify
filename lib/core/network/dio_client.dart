import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

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
      dio.interceptors.add(_ColorLogInterceptor());
    }

    return dio;
  }
}

/// Colors console output by outcome: 2xx/3xx responses print green
/// (success), 4xx responses print yellow (warning), and network/5xx
/// failures print red (error).
class _ColorLogInterceptor extends Interceptor {
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      printEmojis: false,
      noBoxingByDefault: true,
      levelColors: {
        Level.info: const AnsiColor.fg(69), // success - #4A7FF6 blue
        Level.warning: const AnsiColor.fg(226), // warning - yellow
        Level.error: const AnsiColor.fg(196), // error - red
      },
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log(
      Level.debug,
      '→ ${options.method} ${options.uri}\n'
      'Headers: ${options.headers}\n'
      'Body: ${options.data}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final status = response.statusCode ?? 0;
    final level = status >= 400 ? Level.warning : Level.info;
    _log(
      level,
      '← $status ${response.requestOptions.uri}\n'
      'Body: ${response.data}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      Level.error,
      '✗ ${err.requestOptions.method} ${err.requestOptions.uri}\n'
      '${err.message}\n'
      'Response: ${err.response?.data}',
    );
    handler.next(err);
  }

  /// On Android, adb/logcat truncates any single log line around ~1000
  /// chars, which cuts off large JSON bodies. Splitting into fixed-size
  /// chunks keeps every line short enough to survive that.
  static void _log(Level level, String message) {
    const chunkSize = 800;
    for (var i = 0; i < message.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, message.length);
      final chunk = message.substring(i, end);
      switch (level) {
        case Level.warning:
          _logger.w(chunk);
        case Level.error:
          _logger.e(chunk);
        case Level.info:
          _logger.i(chunk);
        default:
          _logger.d(chunk);
      }
    }
  }
}
