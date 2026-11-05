import 'package:tuhfatul_muslim/core/utils/device_platform.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/facebook_sign_in_params.dart';

/// Request body for `POST {baseUrl}{facebookSignInEndPoint}`.
///
/// Only [accessToken] is trusted by the backend: it is verified against
/// Facebook's `debug_token` endpoint, and the e-mail / name / picture are
/// read from the Graph API with that verified token rather than out of this
/// body.
class FacebookSignInRequestModel {
  const FacebookSignInRequestModel({
    required this.accessToken,
    this.fcmToken,
    this.deviceId,
    this.appVersion,
  });

  factory FacebookSignInRequestModel.fromParams(FacebookSignInParams params) {
    return FacebookSignInRequestModel(
      accessToken: params.accessToken,
      fcmToken: params.fcmToken,
      deviceId: params.deviceId,
      appVersion: params.appVersion,
    );
  }

  final String accessToken;
  final String? fcmToken;
  final String? deviceId;
  final String? appVersion;

  /// `platform` always travels with the request (the backend lists it as a
  /// field in its own right), while the optional values are omitted rather
  /// than sent empty — the same shape as [GoogleSignInRequestModel].
  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'platform': devicePlatform,
    if (fcmToken != null && fcmToken!.isNotEmpty) 'fcmToken': fcmToken,
    if (deviceId != null && deviceId!.isNotEmpty) 'deviceId': deviceId,
    if (appVersion != null && appVersion!.isNotEmpty) 'appVersion': appVersion,
  };
}
