/// Value object for the email/password sign-in call.
class LoginParams {
  const LoginParams({required this.email, required this.password});

  final String email;
  final String password;

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
