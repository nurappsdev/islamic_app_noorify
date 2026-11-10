/// Value object for the email/password sign-in call.
class LoginParams {
  const LoginParams({
    required this.email,
    required this.password,
    this.fcmToken,
  });

  final String email;
  final String password;

  /// This device's current FCM token, sent along so the backend can
  /// associate it with the signed-in account. `null` when it isn't
  /// available (see `FirebaseTokenService.getToken`).
  final String? fcmToken;

  /// Returns an error message, or `null` when the input looks valid.
  String? validate() {
    if (!_emailPattern.hasMatch(email.trim())) {
      return 'Please enter a valid email address.';
    }
    if (password.isEmpty) {
      return 'Please enter your password.';
    }
    return null;
  }

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
