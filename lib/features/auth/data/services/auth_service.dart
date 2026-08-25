import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/shared/services/app_globals.dart';
import 'package:islami_app_noorify/shared/services/fcm_token_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  static Future<void>? _googleInitFuture;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser {
    if (!_firebaseReady) return null;
    return _auth.currentUser;
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInitFuture ??= GoogleSignIn.instance.initialize();
  }

  Future<void> _syncLocalProfileFromUser(User? user) async {
    if (user == null) return;

    var changed = false;
    final displayName = (user.displayName ?? '').trim();
    final emailName = (user.email ?? '').split('@').first.trim();
    final remotePhotoUrl = (user.photoURL ?? '').trim();

    if (displayName.isNotEmpty) {
      if (profileNameNotifier.value != displayName) {
        profileNameNotifier.value = displayName;
        changed = true;
      }
    } else if (emailName.isNotEmpty && profileNameNotifier.value != emailName) {
      profileNameNotifier.value = emailName;
      changed = true;
    }

    if (remotePhotoUrl.isNotEmpty) {
      if (profilePhotoUrlNotifier.value != remotePhotoUrl) {
        profilePhotoUrlNotifier.value = remotePhotoUrl;
        changed = true;
      }
    } else {
      final hasCustomLocalPhoto = (profilePhotoBase64Notifier.value ?? '')
          .trim()
          .isNotEmpty;
      if (!hasCustomLocalPhoto && profilePhotoUrlNotifier.value != null) {
        profilePhotoUrlNotifier.value = null;
        changed = true;
      }
    }

    if (changed) {
      await saveAppPreferences();
    }
  }

  Future<void> syncLocalProfileFromCurrentUser() async {
    if (!_firebaseReady) return;
    await _syncLocalProfileFromUser(_auth.currentUser);
  }

  Future<void> _runPostAuthSync(User? user) async {
    if (user == null) return;
    try {
      await _syncLocalProfileFromUser(user);
    } catch (_) {
      // Keep auth flow successful even when local profile sync fails.
    }
    try {
      // Link this device's push token so targeted notifications (e.g. family
      // requests) can reach the user. Never block auth on this.
      await FcmTokenService.instance.registerCurrentToken();
    } catch (_) {
      // Ignore token registration failures.
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _runPostAuthSync(credential.user);
    return credential;
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _runPostAuthSync(credential.user);
    return credential;
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed in user found.',
      );
    }

    final email = user.email;
    final isPasswordUser = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    if (email == null || !isPasswordUser) {
      throw FirebaseAuthException(
        code: 'account-not-password-based',
        message: 'This account does not use password sign-in.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

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
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Missing Google ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    await _runPostAuthSync(userCredential.user);
    return userCredential;
  }

  Future<void> signOut() async {
    // Unlink this device's push token before clearing auth, while the uid is
    // still available, so a signed-out device stops receiving this user's pushes.
    try {
      await FcmTokenService.instance.removeCurrentToken();
    } catch (_) {
      // Ignore token cleanup failures; continue signing out.
    }
    await _auth.signOut();
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore Google SDK sign-out issues for non-Google sessions.
    }
  }

  String messageForException(FirebaseAuthException error, AppText appText) {
    switch (error.code) {
      case 'invalid-email':
        return appText.authErrorInvalidEmail;
      case 'user-disabled':
        return appText.authErrorUserDisabled;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return appText.authErrorWrongCredentials;
      case 'account-not-password-based':
        return appText.authErrorAccountNotPasswordBased;
      case 'email-already-in-use':
        return appText.authErrorEmailInUse;
      case 'weak-password':
        return appText.authErrorWeakPassword;
      case 'operation-not-allowed':
        return appText.authErrorOperationNotAllowed;
      case 'requires-recent-login':
        return appText.authErrorRequiresRecentLogin;
      case 'account-exists-with-different-credential':
        return appText.authErrorAccountExistsDifferentCredential;
      case 'credential-already-in-use':
        return appText.authErrorCredentialAlreadyInUse;
      case 'too-many-requests':
        return appText.authErrorTooManyRequests;
      case 'network-request-failed':
        return appText.authErrorNetworkFailed;
      default:
        return error.message ?? appText.authErrorGeneric;
    }
  }

  String messageForGoogleException(GoogleSignInException error, AppText appText) {
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
}
