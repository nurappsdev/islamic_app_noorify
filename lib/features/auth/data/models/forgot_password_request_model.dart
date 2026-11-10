/// Request body for `POST {baseUrl}{forgotPasswordPoint}`.
class ForgotPasswordRequestModel {
  const ForgotPasswordRequestModel({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email.trim().toLowerCase()};
}
