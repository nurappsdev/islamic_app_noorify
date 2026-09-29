import 'package:tuhfatul_muslim/core/utils/device_platform.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/login_params.dart';

/// Request body for `POST {baseUrl}{signInEndPoint}`.
class LoginRequestModel {
  const LoginRequestModel({
    required this.email,
    required this.password,
    this.fcmToken,
  });

  factory LoginRequestModel.fromParams(LoginParams params) {
    return LoginRequestModel(
      email: params.email.trim().toLowerCase(),
      password: params.password,
      fcmToken: params.fcmToken,
    );
  }

  final String email;
  final String password;
  final String? fcmToken;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    if (fcmToken != null && fcmToken!.isNotEmpty) ...{
      'fcmToken': fcmToken,
      'platform': devicePlatform,
    },
  };
}
