import 'package:hive/hive.dart';

import 'package:islami_app_noorify/core/storage/hive_service.dart';

/// Local (Hive-backed) persistence for the auth session.
abstract interface class AuthLocalDataSource {
  /// Persists the auth token from a successful sign-in.
  Future<void> cacheToken(String token);

  /// The stored token, or `null` when signed out.
  String? getToken();

  /// `true` when a token is currently stored.
  bool get hasToken;

  /// Removes the stored tokens so the session is completely cleared.
  Future<void> clearToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({Box<dynamic>? box}) : _box = box ?? HiveService.auth;

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _refreshCookieNameKey = 'refresh_cookie_name';

  final Box<dynamic> _box;

  @override
  Future<void> cacheToken(String token) => _box.put(_tokenKey, token);

  @override
  String? getToken() {
    final value = _box.get(_tokenKey);
    return value is String && value.isNotEmpty ? value : null;
  }

  @override
  bool get hasToken => getToken() != null;

  /// Persists the refresh token used to renew an expired access token.
  /// [cookieName] is the name it arrived under when the server set it as a
  /// cookie, so it can be sent back the same way.
  Future<void> cacheRefreshToken(String token, {String? cookieName}) async {
    await _box.put(_refreshTokenKey, token);
    if (cookieName != null) await _box.put(_refreshCookieNameKey, cookieName);
  }

  String? getRefreshToken() {
    final value = _box.get(_refreshTokenKey);
    return value is String && value.isNotEmpty ? value : null;
  }

  String? getRefreshCookieName() {
    final value = _box.get(_refreshCookieNameKey);
    return value is String && value.isNotEmpty ? value : null;
  }

  @override
  Future<void> clearToken() async {
    await _box.delete(_tokenKey);
    await _box.delete(_refreshTokenKey);
    await _box.delete(_refreshCookieNameKey);
  }
}
