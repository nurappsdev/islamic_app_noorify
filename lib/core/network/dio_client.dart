import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'package:tuhfatul_muslim/core/network/auth_refresh_interceptor.dart';
import 'package:tuhfatul_muslim/core/services/api_constants.dart';

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

    // Sent on every request (GET/POST/PUT/PATCH/DELETE alike) since it lives
    // on the shared BaseOptions, not on any one call site.
    dio.options.headers.addAll({
      'Accept': 'application/json',
      'X-API-Key': ApiConstants.apiKey,
    });

    if (kDebugMode) {
      dio.interceptors.add(_ColorLogInterceptor());
    }
    dio.interceptors.add(AuthRefreshInterceptor(dio: dio));

    return dio;
  }
}

/// Colors console output by outcome: 2xx/3xx responses print green
/// (success), 4xx responses print yellow (warning), and network/5xx
/// failures print red (error).
/// Test seam: exposes the log redaction used by the request logger, so a test
/// can prove credentials never reach logcat.
@visibleForTesting
Object? debugRedactLogData(Object? data) => _ColorLogInterceptor.debugRedact(data);

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
      'Headers: ${_redact(options.headers)}\n'
      'Body: ${_redact(options.data)}',
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
      'Body: ${_redact(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      Level.error,
      '✗ ${err.requestOptions.method} ${err.requestOptions.uri}\n'
      '${err.message}\n'
      'Response: ${_redact(err.response?.data)}',
    );
    handler.next(err);
  }

  /// Credentials that must never reach logcat: an ID token or a session
  /// token read out of a log is enough to impersonate the user, and logs get
  /// pasted into chats and bug reports.
  static const _secretKeys = {
    'idtoken',
    'id_token',
    'accesstoken',
    'access_token',
    'refreshtoken',
    'refresh_token',
    'token',
    'jwt',
    'password',
    'fcmtoken',
    'fcm_token',
    'authorization',
    'x-api-key',
  };

  /// Returns [data] with every secret value replaced by its length, which is
  /// enough to tell "empty/missing" from "present" while debugging.
  static Object? debugRedact(Object? data) => _redact(data);

  static Object? _redact(Object? data) {
    if (data is Map) {
      return {
        for (final entry in data.entries)
          entry.key: _secretKeys.contains(
                entry.key.toString().toLowerCase(),
              )
              ? '<redacted ${entry.value?.toString().length ?? 0} chars>'
              : _redact(entry.value),
      };
    }
    if (data is List) return data.map(_redact).toList();
    return data;
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
