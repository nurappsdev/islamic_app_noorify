/// Value object for the "set a new password after OTP" call.
class ResetPasswordParams {
  const ResetPasswordParams({
    required this.resetToken,
    required this.password,
    required this.confirmPassword,
  });

  /// Short-lived token returned by OTP verification.
  final String resetToken;
  final String password;
  final String confirmPassword;

  /// Returns an error message, or `null` when the input looks valid.
  String? validate() {
    if (resetToken.trim().isEmpty) {
      return 'Your reset session has expired. Please request a new code.';
    }
    if (password.length < 8 ||
        !password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'[0-9]')) ||
        !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'))) {
      return 'Password must be at least 8 characters and include an '
          'uppercase letter, a number and a special character.';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }
}
