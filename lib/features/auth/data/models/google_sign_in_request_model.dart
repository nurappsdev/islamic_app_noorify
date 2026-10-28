import 'package:tuhfatul_muslim/core/utils/device_platform.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/google_sign_in_params.dart';

/// Request body for `POST {baseUrl}{googleSignInEndPoint}`.
///
/// Only [idToken] is trusted by the backend: it is verified against Google's
/// public keys, and the e-mail / name / picture are read out of the verified
/// token rather than out of this body.
class GoogleSignInRequestModel {
  const GoogleSignInRequestModel({required this.idToken, this.fcmToken});

  factory GoogleSignInRequestModel.fromParams(GoogleSignInParams params) {
    return GoogleSignInRequestModel(
      idToken: params.idToken,
      fcmToken: params.fcmToken,
    );
  }

  final String idToken;
  final String? fcmToken;

  Map<String, dynamic> toJson() => {
    'idToken': idToken,
    if (fcmToken != null && fcmToken!.isNotEmpty) ...{
      'fcmToken': fcmToken,
      'platform': devicePlatform,
    },
  };
}
