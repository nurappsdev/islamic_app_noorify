abstract class LoginEvent {
  const LoginEvent();
}

/// Fired when the user submits the sign-in form.
class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({
    required this.email,
    required this.password,
    this.fcmToken,
  });

  final String email;
  final String password;

  /// This device's current FCM token, sent to the backend with the login
  /// request so it can be associated with the signed-in account.
  final String? fcmToken;
}

/// Fired once the Google SDK has returned an ID token, to exchange it for an
/// app session. The Google account picker itself runs in the screen, so a
/// cancelled picker never reaches the bloc.
class GoogleLoginSubmitted extends LoginEvent {
  const GoogleLoginSubmitted({
    required this.idToken,
    this.email,
    this.displayName,
    this.photoUrl,
    this.fcmToken,
  });

  final String idToken;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// This device's current FCM token, sent to the backend with the request
  /// so it can be associated with the signed-in account.
  final String? fcmToken;
}

/// Resets the bloc back to its initial state (e.g. after showing an error).
class LoginReset extends LoginEvent {
  const LoginReset();
}
