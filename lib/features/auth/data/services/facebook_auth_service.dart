import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'package:tuhfatul_muslim/core/services/facebook_auth_config.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

/// Raised when Facebook login does not produce a usable access token, so
/// callers can tell a cancel / misconfiguration apart from a backend failure
/// exactly as they already do for `GoogleSignInException`.
class FacebookAuthException implements Exception {
  const FacebookAuthException({required this.status, this.description});

  final LoginStatus status;
  final String? description;

  @override
  String toString() =>
      'FacebookAuthException(status: ${status.name}, '
      'description: $description)';
}

/// What a completed Facebook login hands back to the data layer.
///
/// [accessToken] is the only part the backend trusts — it is verified against
/// Facebook's debug_token endpoint and the profile is read from the Graph API
/// server-side. Everything else is kept purely so the UI can show a name or
/// avatar without waiting for `GET /user/me`.
class FacebookAuthResult {
  const FacebookAuthResult({
    required this.accessToken,
    required this.facebookId,
    this.email,
    this.displayName,
    this.photoUrl,
    this.expiresAt,
  });

  final String accessToken;
  final String facebookId;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// When the token stops being valid, when the platform reports it. Only
  /// informational on the device; the backend re-checks expiry itself.
  final DateTime? expiresAt;
}

/// Facebook Login on top of the native Facebook SDK, with **no Firebase
/// Authentication** involved — the same shape as [GoogleAuthService].
///
/// The job here stops at obtaining a Facebook access token; exchanging it for
/// an app session is the REST backend's. The App Secret never touches the
/// device, so the token is useless to anyone until the backend verifies it.
class FacebookAuthService {
  FacebookAuthService._();

  static final FacebookAuthService instance = FacebookAuthService._();

  /// Prompts the user to log in with Facebook and returns the resulting
  /// access token plus whatever profile fields Facebook released.
  ///
  /// Throws a [FacebookAuthException] when the user cancels, another login is
  /// already running, or the SDK is misconfigured.
  Future<FacebookAuthResult> signIn() async {
    if (!FacebookAuthConfig.isConfigured) {
      throw const FacebookAuthException(
        status: LoginStatus.failed,
        description: 'No Facebook App ID is configured for this build.',
      );
    }

    final result = await FacebookAuth.instance.login(
      permissions: FacebookAuthConfig.loginPermissions,
      // Hands the login to the installed Facebook app when there is one and
      // falls back to a Custom Tab otherwise. `dialogOnly` (the plugin's
      // default) would skip single sign-on even when the app is present.
      loginBehavior: LoginBehavior.nativeWithFallback,
    );

    if (result.status != LoginStatus.success || result.accessToken == null) {
      // Never log the token itself — only the failure metadata.
      debugPrint(
        '[FacebookAuth] login failed: status=${result.status.name} '
        'message=${result.message}',
      );
      if (result.status != LoginStatus.cancelled) {
        await clearStaleSession();
      }
      throw FacebookAuthException(
        status: result.status,
        description: result.message,
      );
    }

    final token = result.accessToken!;
    if (token.tokenString.isEmpty) {
      throw const FacebookAuthException(
        status: LoginStatus.failed,
        description: 'Facebook returned an empty access token.',
      );
    }

    // `email` is a permission the user can decline, and a profile created
    // from a phone number may not have one at all, so it stays nullable all
    // the way to the backend.
    Map<String, dynamic> profile = const {};
    try {
      profile = await FacebookAuth.instance.getUserData(
        fields: FacebookAuthConfig.graphUserFields,
      );
    } catch (e) {
      // A Graph hiccup must not fail a login that already succeeded: the
      // token is what matters, and the backend re-reads the profile anyway.
      debugPrint('[FacebookAuth] could not read profile: $e');
    }

    // Safe to log: identifiers and shapes only. The token itself is never
    // printed — only its length, which is enough to tell "empty/truncated"
    // from "looks right" when debugging. Guarded so user ids stay out of
    // release logs.
    if (kDebugMode) {
      debugPrint(
        '[FacebookAuth] login ok: type=${token.type.name} '
        'userId=${_facebookIdOf(token, profile)} '
        'tokenLength=${token.tokenString.length} '
        'emailGranted=${profile['email'] != null} '
        'expires=${token is ClassicToken ? token.expires.toIso8601String() : 'n/a'}',
      );
    }

    return FacebookAuthResult(
      accessToken: token.tokenString,
      facebookId: _facebookIdOf(token, profile),
      email: _nonEmpty(profile['email'] as String?) ?? _emailOf(token),
      displayName: _nonEmpty(profile['name'] as String?) ?? _nameOf(token),
      photoUrl: _photoUrlOf(profile),
      expiresAt: token is ClassicToken ? token.expires : null,
    );
  }

  /// The Facebook user id, from whichever of the two token shapes came back,
  /// falling back to the Graph response.
  static String _facebookIdOf(AccessToken token, Map<String, dynamic> profile) {
    if (token is ClassicToken) return token.userId;
    if (token is LimitedToken) return token.userId;
    return (profile['id'] as String?) ?? '';
  }

  /// A [LimitedToken] (iOS limited login) carries the profile inline, since
  /// the Graph API is not callable with it.
  static String? _emailOf(AccessToken token) =>
      token is LimitedToken ? _nonEmpty(token.userEmail) : null;

  static String? _nameOf(AccessToken token) =>
      token is LimitedToken ? _nonEmpty(token.userName) : null;

  /// Digs the avatar out of the nested `picture.data.url` Graph shape.
  static String? _photoUrlOf(Map<String, dynamic> profile) {
    final picture = profile['picture'];
    if (picture is! Map) return null;
    final data = picture['data'];
    if (data is! Map) return null;
    return _nonEmpty(data['url'] as String?);
  }

  static String? _nonEmpty(String? value) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Localized confirmation that the Facebook login itself succeeded.
  ///
  /// Names the account when Facebook released a name or e-mail; `email` is a
  /// declinable permission, so neither is guaranteed.
  static String successMessageFor(FacebookAuthResult result, AppText appText) {
    final who = result.displayName ?? result.email;
    if (who == null) return appText.facebookAuthSignedIn;
    return appText.facebookAuthSignedInAs.replaceAll('{name}', who);
  }

  /// Localized text for a [FacebookAuthException]. Returns an empty string
  /// when the user simply cancelled, which callers treat as "show nothing" —
  /// the same contract as [GoogleAuthService.messageFor].
  static String messageFor(FacebookAuthException error, AppText appText) {
    switch (error.status) {
      case LoginStatus.cancelled:
        return '';
      case LoginStatus.operationInProgress:
        return appText.facebookAuthErrorInProgress;
      case LoginStatus.failed:
      case LoginStatus.success:
        return error.description ?? appText.facebookAuthErrorGeneric;
    }
  }

  /// Drops any cached Facebook session so the next attempt starts clean.
  /// Used after a failed login, and after the backend rejects a token.
  Future<void> clearStaleSession() async {
    try {
      await FacebookAuth.instance.logOut();
      debugPrint('[FacebookAuth] cleared cached session');
    } catch (e) {
      debugPrint('[FacebookAuth] could not clear cached session: $e');
    }
  }

  /// Clears the Facebook SDK's own session. Safe to call when the user never
  /// logged in with Facebook — it is a no-op then.
  Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {
      // Never let Facebook SDK cleanup block signing out of the app.
    }
  }
}
