import 'package:islami_app_noorify/features/auth/domain/entities/register_params.dart';

/// Request body for `POST {baseUrl}{signUpEndPoint}`.
class RegisterRequestModel {
  const RegisterRequestModel({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.gender,
  });

  factory RegisterRequestModel.fromParams(RegisterParams params) {
    return RegisterRequestModel(
      name: params.name.trim(),
      email: params.email.trim().toLowerCase(),
      password: params.password,
      phone: params.phone?.trim(),
      gender: params.gender?.trim(),
    );
  }

  final String name;
  final String email;
  final String password;
  final String? phone;
  final String? gender;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (gender != null && gender!.isNotEmpty) 'gender': gender,
    };
  }
}
