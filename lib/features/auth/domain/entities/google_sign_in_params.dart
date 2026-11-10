/// Value object for the Google sign-in call.
///
/// Carries the Google ID token obtained on the device through to the REST
/// backend, which verifies it and returns an app session.
class GoogleSignInParams {
  const GoogleSignInParams({
    required this.idToken,
    this.email,
    this.displayName,
    this.photoUrl,
    this.fcmToken,
    this.deviceId,
    this.appVersion,
  });

  /// The signed JWT from Google. The backend verifies this; nothing else in
  /// this object is trusted server-side.
  final String idToken;

  /// Read from the same token, kept only so the UI has something to show
  /// before the profile is fetched.
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
    if (idToken.trim().isEmpty) {
      return 'Google did not return a sign-in token. Please try again.';
    }
    return null;
  }
}
