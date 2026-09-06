import 'package:islami_app_noorify/features/auth/domain/entities/login_params.dart';

/// Request body for `POST {baseUrl}{signInEndPoint}`.
class LoginRequestModel {
  const LoginRequestModel({required this.email, required this.password});

  factory LoginRequestModel.fromParams(LoginParams params) {
    return LoginRequestModel(
      email: params.email.trim().toLowerCase(),
      password: params.password,
    );
  }

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
