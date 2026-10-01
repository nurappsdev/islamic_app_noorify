abstract class ResetPasswordEvent {
  const ResetPasswordEvent();
}

/// Fired when the user submits the new-password form.
class ResetPasswordSubmitted extends ResetPasswordEvent {
  const ResetPasswordSubmitted({
    required this.resetToken,
    required this.password,
    required this.confirmPassword,
  });

  /// Token from OTP verification that authorises the reset.
  final String resetToken;
  final String password;
  final String confirmPassword;
}

/// Resets the bloc back to its initial state (e.g. after showing an error).
class ResetPasswordReset extends ResetPasswordEvent {
  const ResetPasswordReset();
}
