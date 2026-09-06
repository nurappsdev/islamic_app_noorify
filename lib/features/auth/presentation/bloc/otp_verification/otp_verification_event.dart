abstract class OtpVerificationEvent {
  const OtpVerificationEvent();
}

/// Fired when the user submits the 6-digit code.
class OtpSubmitted extends OtpVerificationEvent {
  const OtpSubmitted({required this.email, required this.otp});

  final String email;
  final String otp;
}

/// Resets the bloc back to its initial state (e.g. after showing an error).
class OtpVerificationReset extends OtpVerificationEvent {
  const OtpVerificationReset();
}
