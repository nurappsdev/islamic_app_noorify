import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/features/auth/data/models/auth_user_model.dart';

/// Parsed `data` payload of a successful login response.
///
/// The backend (passport + refresh-token cookie) returns the access token in
/// `data`; the refresh token is an http-only cookie we never touch here.
/// Field name is read defensively (`accessToken` / `token` / `access_token`).
class LoginResponseModel {
  const LoginResponseModel({required this.token, this.user});

  factory LoginResponseModel.fromJson(
    Map<String, dynamic> data, {
    String? headerToken,
  }) {
    final token = _firstNonEmpty([
      data['accessToken'],
      data['token'],
      data['access_token'],
      data['jwt'],
      headerToken,
    ]);
    if (token == null) {
      throw ParsingException(
        'Login succeeded but no auth token was found in the response.',
      );
    }

    final rawUser = data['user'] ?? data['data'];
    AuthUserModel? user;
    if (rawUser is Map<String, dynamic>) {
      try {
        user = AuthUserModel.fromJson(rawUser);
      } on ParsingException {
        user = null;
      }
    }

    return LoginResponseModel(token: token, user: user);
  }

  final String token;
  final AuthUserModel? user;

  static String? _firstNonEmpty(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) {
        return c.trim().replaceFirst(
          RegExp(r'^Bearer\s+', caseSensitive: false),
          '',
        );
      }
    }
    return null;
  }
}
