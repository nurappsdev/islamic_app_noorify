/// Request body for `POST {baseUrl}{logoutEndPoint}`.
///
/// The server revokes [refreshToken] so the session can never be renewed,
/// and unregisters [fcmToken] so this device stops receiving the account's
/// pushes. Both are omitted rather than sent empty: a session that never
/// received a refresh token, or a device without push permission, still has
/// to be able to sign out.
class LogoutRequestModel {
  const LogoutRequestModel({this.refreshToken, this.fcmToken});

  final String? refreshToken;
  final String? fcmToken;

  Map<String, dynamic> toJson() => {
    if (refreshToken != null && refreshToken!.isNotEmpty)
      'refreshToken': refreshToken,
    if (fcmToken != null && fcmToken!.isNotEmpty) 'fcmToken': fcmToken,
  };
}
