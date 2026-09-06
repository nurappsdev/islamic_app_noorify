/// Outcome of a successful OTP verification.
///
/// The email-verification flow only needs [message]. The forgot-password flow
/// also gets a short-lived [resetToken] that authorises `POST /auth/reset-password`.
class OtpVerificationResult {
  const OtpVerificationResult({required this.message, this.resetToken});

  final String message;
  final String? resetToken;
}
