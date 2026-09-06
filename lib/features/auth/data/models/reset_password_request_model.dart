import 'package:islami_app_noorify/features/auth/domain/entities/reset_password_params.dart';

/// Request body for `POST {baseUrl}{resetPasswordEndPoint}`.
///
/// The reset token is NOT part of the body — it travels in the
/// `Authorization: Bearer <token>` header (see [AuthRemoteDataSource.resetPassword]).
class ResetPasswordRequestModel {
  const ResetPasswordRequestModel({required this.password});

  factory ResetPasswordRequestModel.fromParams(ResetPasswordParams params) {
    return ResetPasswordRequestModel(password: params.password);
  }

  final String password;

  Map<String, dynamic> toJson() => {'password': password};
}
