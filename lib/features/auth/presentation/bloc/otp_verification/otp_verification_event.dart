abstract class OtpVerificationEvent {
  const OtpVerificationEvent();
}

/// Fired when the user submits the 6-digit code.
class OtpSubmitted extends OtpVerificationEvent {
  const OtpSubmitted({required this.email, required this.otp});

  final String email;
  final String otp;
}

/// Fired when the user taps "Resend code".
class OtpResendRequested extends OtpVerificationEvent {
  const OtpResendRequested(this.email);

  final String email;
}

/// Resets the verify part of the state (e.g. after showing an error).
class OtpVerificationReset extends OtpVerificationEvent {
  const OtpVerificationReset();
}
