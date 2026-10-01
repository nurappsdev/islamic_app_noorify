import 'dart:async';

import 'package:dio/dio.dart';

import 'package:tuhfatul_muslim/core/services/api_constants.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';

/// Renews an expired access token and replays the request that failed.
///
/// Data sources attach `Authorization: Bearer <token>` themselves. When the
/// server answers such a request with 401, this interceptor exchanges the
/// stored refresh token for a new access token (one refresh shared by every
/// request that failed together), stores it, and retries the request once.
///
/// The refresh token is captured from the auth endpoints' responses, whether
/// the server sends it in the body or as a `Set-Cookie` header.
class AuthRefreshInterceptor extends Interceptor {
  AuthRefreshInterceptor({
    required this.dio,
    AuthLocalDataSourceImpl? local,
    Dio? refreshDio,
  }) : _localOverride = local,
       _refreshDio = refreshDio ?? _defaultRefreshDio;

  /// The client whose failed requests are replayed.
  final Dio dio;
  final AuthLocalDataSourceImpl? _localOverride;
  final Dio _refreshDio;

  // Resolved lazily: Hive is only guaranteed open once the app has started.
  late final AuthLocalDataSourceImpl _local =
      _localOverride ?? AuthLocalDataSourceImpl();

  /// Called once when the session cannot be renewed (no refresh token, or the
  /// server rejected it) and the user has to sign in again.
  static Future<void> Function()? onSessionExpired;

  static const _retriedKey = 'auth_refresh_retried';
  static const _authPathPrefix = '/auth/';

  /// The refresh in flight, shared across every Dio instance and request.
  static Future<String?>? _inFlight;

  /// Bare client for the refresh call, so it can never re-enter this
  /// interceptor.
  static final Dio _defaultRefreshDio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: {'Accept': 'application/json',
        'X-API-Key': 'c954a39d0ce7ff714e0e87f15a21c5a1cfde41787c2b4a3e6ec0417a2e4bfb9a',
      },
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    try {
      await _captureRefreshToken(response);

      final options = response.requestOptions;
      if (response.statusCode != 401 || !_isRefreshable(options)) {
        return handler.next(response);
      }

      final fresh = await _freshTokenFor(options);
      if (fresh == null) return handler.next(response);

      handler.resolve(await dio.fetch<dynamic>(_withToken(options, fresh)));
    } on DioException catch (e) {
      handler.reject(e);
    } catch (_) {
      handler.next(response);
    }
  }

  /// Only a first attempt that carried a bearer token, and that isn't itself an
  /// auth call (login/OTP/reset failures are real errors, not expiry).
  bool _isRefreshable(RequestOptions options) {
    if (options.extra[_retriedKey] == true) return false;
    if (options.path.startsWith(_authPathPrefix)) return false;
    return _bearerOf(options) != null;
  }

  String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is! String || !header.startsWith('Bearer ')) return null;
    return header.substring(7);
  }

  /// The token to retry [options] with, or `null` when it can't be renewed.
  Future<String?> _freshTokenFor(RequestOptions options) async {
    final stored = _local.getToken();
    if (stored == null) return null; // signed out while the request ran
    // Another request already refreshed while this one was in flight.
    if (stored != _bearerOf(options)) return stored;

    return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
  }

  RequestOptions _withToken(RequestOptions options, String token) {
    final data = options.data;
    return options.copyWith(
      headers: {...options.headers, 'Authorization': 'Bearer $token'},
      extra: {...options.extra, _retriedKey: true},
      // A FormData body is single-use; the retry needs its own copy.
      data: data is FormData ? data.clone() : data,
    );
  }

  /// Returns the new access token, or `null` on failure. Signs the user out
  /// only when the server definitively rejects the refresh token; a network
  /// error leaves the session intact so a later request can try again.
  Future<String?> _refresh() async {
    final refreshToken = _local.getRefreshToken();
    if (refreshToken == null) {
      await _expireSession();
      return null;
    }

    final Response<dynamic> response;
    try {
      response = await _refreshDio.post<dynamic>(
        ApiConstants.refreshTokenEndPoint,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {
            'Cookie':
                '${_local.getRefreshCookieName() ?? 'refreshToken'}=$refreshToken',
          },
        ),
      );
    } on DioException {
      return null;
    }

    final status = response.statusCode ?? 0;
    final json = _asMap(response.data);
    if (status >= 200 && status < 300 && json['success'] != false) {
      final token = _accessTokenFrom(json);
      if (token == null) return null;
      await _local.cacheToken(token);
      await _captureRefreshToken(response); // rotated token
      return token;
    }

    if (status == 400 || status == 401 || status == 403) {
      await _expireSession();
    }
    return null;
  }

  Future<void> _expireSession() async {
    await _local.clearToken();
    await onSessionExpired?.call();
  }

  /// Stores the refresh token from a successful auth-endpoint response.
  Future<void> _captureRefreshToken(Response<dynamic> response) async {
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) return;
    if (!response.requestOptions.path.startsWith(_authPathPrefix)) return;

    for (final raw in response.headers['set-cookie'] ?? const <String>[]) {
      final pair = raw.split(';').first;
      final i = pair.indexOf('=');
      if (i <= 0) continue;
      final name = pair.substring(0, i).trim();
      final value = pair.substring(i + 1).trim();
      if (name.toLowerCase().contains('refresh') && value.isNotEmpty) {
        await _local.cacheRefreshToken(value, cookieName: name);
        return;
      }
    }

    final json = _asMap(response.data);
    final data = json['data'];
    for (final source in [if (data is Map) _asMap(data), json]) {
      final token = source['refreshToken'] ?? source['refresh_token'];
      if (token is String && token.trim().isNotEmpty) {
        await _local.cacheRefreshToken(token.trim());
        return;
      }
    }
  }

  String? _accessTokenFrom(Map<String, dynamic> json) {
    final data = json['data'];
    for (final source in [if (data is Map) _asMap(data), json]) {
      final token =
          source['accessToken'] ?? source['token'] ?? source['access_token'];
      if (token is String && token.trim().isNotEmpty) {
        return token.trim().replaceFirst(
          RegExp(r'^Bearer\s+', caseSensitive: false),
          '',
        );
      }
    }
    return null;
  }

  Map<String, dynamic> _asMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};
}
