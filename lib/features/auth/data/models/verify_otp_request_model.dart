import 'package:islami_app_noorify/features/auth/domain/entities/verify_otp_params.dart';

/// Request body for `POST {baseUrl}{verifyEmailEndPoint}`.
class VerifyOtpRequestModel {
  const VerifyOtpRequestModel({required this.email, required this.otp});

  factory VerifyOtpRequestModel.fromParams(VerifyOtpParams params) {
    return VerifyOtpRequestModel(
      email: params.email.trim().toLowerCase(),
      otp: params.otp.trim(),
    );
  }

  final String email;
  final String otp;

  Map<String, dynamic> toJson() => {'email': email, 'otp': otp};
}
