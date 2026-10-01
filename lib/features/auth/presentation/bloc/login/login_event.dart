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

/// Resets the bloc back to its initial state (e.g. after showing an error).
class LoginReset extends LoginEvent {
  const LoginReset();
}
