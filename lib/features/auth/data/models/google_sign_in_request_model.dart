import 'package:tuhfatul_muslim/core/utils/device_platform.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/google_sign_in_params.dart';

/// Request body for `POST {baseUrl}{googleSignInEndPoint}`.
///
/// Only [idToken] is trusted by the backend: it is verified against Google's
/// public keys, and the e-mail / name / picture are read out of the verified
/// token rather than out of this body.
class GoogleSignInRequestModel {
  const GoogleSignInRequestModel({
    required this.idToken,
    this.fcmToken,
    this.deviceId,
    this.appVersion,
  });

  factory GoogleSignInRequestModel.fromParams(GoogleSignInParams params) {
    return GoogleSignInRequestModel(
      idToken: params.idToken,
      fcmToken: params.fcmToken,
      deviceId: params.deviceId,
      appVersion: params.appVersion,
    );
  }

  final String idToken;
  final String? fcmToken;
  final String? deviceId;
  final String? appVersion;

  /// `platform` always travels with the request (the backend lists it as a
  /// field in its own right), while the optional values are omitted rather
  /// than sent empty.
  Map<String, dynamic> toJson() => {
    'idToken': idToken,
    'platform': devicePlatform,
    if (fcmToken != null && fcmToken!.isNotEmpty) 'fcmToken': fcmToken,
    if (deviceId != null && deviceId!.isNotEmpty) 'deviceId': deviceId,
    if (appVersion != null && appVersion!.isNotEmpty) 'appVersion': appVersion,
  };
}
