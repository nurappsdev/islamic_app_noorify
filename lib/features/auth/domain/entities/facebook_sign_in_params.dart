/// Value object for the Facebook sign-in call.
///
/// Carries the Facebook access token obtained on the device through to the
/// REST backend, which verifies it and returns an app session. Mirrors
/// [GoogleSignInParams] field for field.
class FacebookSignInParams {
  const FacebookSignInParams({
    required this.accessToken,
    this.email,
    this.displayName,
    this.photoUrl,
    this.fcmToken,
    this.deviceId,
    this.appVersion,
  });

  /// The opaque access token from Facebook. The backend verifies this against
  /// Facebook's `debug_token` endpoint; nothing else in this object is
  /// trusted server-side.
  final String accessToken;

  /// Read from the same login, kept only so the UI has something to show
  /// before the profile is fetched. [email] can legitimately be null: the
  /// `email` permission is declinable.
  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// This device's current FCM token, sent along so the backend can
  /// associate it with the signed-in account.
  final String? fcmToken;

  /// Stable per-install identifier and the running app version, both from
  /// [DeviceIdentityService]. `null` when the platform could not supply them,
  /// in which case the field is simply left out of the request.
  final String? deviceId;
  final String? appVersion;

  /// Returns an error message, or `null` when the input looks valid.
  String? validate() {
    if (accessToken.trim().isEmpty) {
      return 'Facebook did not return a sign-in token. Please try again.';
    }
    return null;
  }
}
