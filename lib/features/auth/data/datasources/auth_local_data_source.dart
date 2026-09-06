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

  /// Removes the stored token so the session is completely cleared.
  Future<void> clearToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({Box<dynamic>? box}) : _box = box ?? HiveService.auth;

  static const String _tokenKey = 'auth_token';

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

  @override
  Future<void> clearToken() => _box.delete(_tokenKey);
}
