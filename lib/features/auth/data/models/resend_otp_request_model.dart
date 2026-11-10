/// Request body for `POST {baseUrl}{resendOtpEndPoint}`.
class ResendOtpRequestModel {
  const ResendOtpRequestModel({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email.trim().toLowerCase()};
}
