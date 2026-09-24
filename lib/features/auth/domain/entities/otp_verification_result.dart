/// Outcome of a successful OTP verification.
///
/// The email-verification flow only needs [message]. The forgot-password flow
/// also gets a short-lived [resetToken] that authorises `POST /auth/reset-password`.
class OtpVerificationResult {
  const OtpVerificationResult({
    required this.message,
    this.resetToken,
    this.accessToken,
  });

  final String message;
  final String? resetToken;

  /// Session token the API may return when it verifies a new account's
  /// e-mail (sign-up flow); used to sign the user in.
  final String? accessToken;
}
