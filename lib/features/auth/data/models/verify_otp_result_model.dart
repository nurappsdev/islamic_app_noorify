import 'package:islami_app_noorify/features/auth/domain/entities/otp_verification_result.dart';

/// Parses the envelope of a successful `POST {verifyEmailEndPoint}` response:
/// `{ success, message, data: { resetToken? / token? / accessToken? } }`.
class VerifyOtpResultModel extends OtpVerificationResult {
  const VerifyOtpResultModel({
    required super.message,
    super.resetToken,
    super.accessToken,
  });

  factory VerifyOtpResultModel.fromEnvelope(Map<String, dynamic> json) {
    final data = json['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final token = _firstNonEmpty([
      map['resetToken'],
      map['reset_token'],
      map['token'],
      map['accessToken'],
    ]);
    return VerifyOtpResultModel(
      message: json['message']?.toString() ?? 'OTP verified.',
      resetToken: token,
      accessToken: _firstNonEmpty([
        map['accessToken'],
        map['access_token'],
        map['jwt'],
        map['token'],
      ]),
    );
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      if (v is String && v.trim().isNotEmpty) {
        return v.trim().replaceFirst(
          RegExp(r'^Bearer\s+', caseSensitive: false),
          '',
        );
      }
    }
    return null;
  }
}
