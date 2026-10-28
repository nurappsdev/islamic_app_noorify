import 'package:google_sign_in/google_sign_in.dart';

import 'package:tuhfatul_muslim/core/services/google_auth_config.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

/// What a completed Google sign-in hands back to the data layer.
///
/// [idToken] is the only part the backend trusts — everything else is taken
/// from the same token and is kept here purely so the UI can show a name or
/// avatar without waiting for `GET /user/me`.
class GoogleAuthResult {
  const GoogleAuthResult({
    required this.idToken,
    required this.googleId,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String idToken;
  final String googleId;
  final String email;
  final String? displayName;
  final String? photoUrl;
}

/// Google Sign-In on top of Google Identity Services, with **no Firebase
/// Authentication** involved.
///
/// The job here stops at obtaining a Google ID token; exchanging it for an
/// app session is the REST backend's (`POST /auth/google`). Firebase stays in
/// the app for messaging and the rest, it just plays no part in this flow.
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  Future<void>? _initFuture;

  /// Initializes the SDK once per process. A failed attempt is *not* cached,
  /// so a transient failure (e.g. Play Services updating) can be retried.
  Future<void> _ensureInitialized() {
    final pending = _initFuture;
    if (pending != null) return pending;

    final future = GoogleSignIn.instance.initialize(
      clientId: GoogleAuthConfig.iosClientIdOrNull,
      serverClientId: GoogleAuthConfig.serverClientId,
    );
    _initFuture = future.catchError((Object error) {
      _initFuture = null;
      throw error;
    });
    return _initFuture!;
  }

  /// Prompts the user to pick a Google account and returns the resulting ID
  /// token.
  ///
  /// Throws a [GoogleSignInException] when the user cancels or the SDK is
  /// misconfigured, so callers can tell those apart from a backend failure.
  Future<GoogleAuthResult> signIn() async {
    if (!GoogleAuthConfig.isConfigured) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description:
            'No Google server client ID is configured for this build.',
      );
    }

    await _ensureInitialized();

    final googleSignIn = GoogleSignIn.instance;
    final GoogleSignInAccount account;
    if (googleSignIn.supportsAuthenticate()) {
      account = await googleSignIn.authenticate();
    } else {
      final lightweight = await googleSignIn.attemptLightweightAuthentication();
      if (lightweight == null) {
        throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.uiUnavailable,
          description: 'Google Sign-In is unavailable on this platform.',
        );
      }
      account = lightweight;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.providerConfigurationError,
        description:
            'Google returned no ID token. Check that the server client ID '
            'and this build\'s signing certificate are both registered.',
      );
    }

    return GoogleAuthResult(
      idToken: idToken,
      googleId: account.id,
      email: account.email,
      displayName: (account.displayName ?? '').trim().isEmpty
          ? null
          : account.displayName,
      photoUrl: account.photoUrl,
    );
  }

  /// Localized text for a [GoogleSignInException]. Returns an empty string
  /// when the user simply cancelled, which callers treat as "show nothing".
  static String messageFor(GoogleSignInException error, AppText appText) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return '';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return appText.googleAuthErrorNotConfigured;
      case GoogleSignInExceptionCode.uiUnavailable:
        return appText.googleAuthErrorUiUnavailable;
      case GoogleSignInExceptionCode.interrupted:
        return appText.googleAuthErrorInterrupted;
      default:
        return error.description ?? appText.googleAuthErrorGeneric;
    }
  }

  /// Clears the Google SDK's own session. Safe to call when the user never
  /// signed in with Google — it is a no-op then.
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Never let Google SDK cleanup block signing out of the app.
    }
  }
}
