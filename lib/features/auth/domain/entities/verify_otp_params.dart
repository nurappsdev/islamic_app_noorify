/// Value object for the "verify email OTP" call.
class VerifyOtpParams {
  const VerifyOtpParams({
    required this.email,
    required this.otp,
    this.startSession = false,
  });

  final String email;
  final String otp;

  /// Sign-up flow: keep the access token from the response as the session.
  /// Left `false` for forgot-password, whose token only authorises a reset.
  final bool startSession;

  /// Returns an error message, or `null` when the input looks valid.
  String? validate() {
    if (!_emailPattern.hasMatch(email.trim())) {
      return 'Please enter a valid email address.';
    }
    if (!_otpPattern.hasMatch(otp.trim())) {
      return 'Enter the 6-digit code sent to your email.';
    }
    return null;
  }

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _otpPattern = RegExp(r'^\d{6}$');
}
