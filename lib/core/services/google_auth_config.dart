/// OAuth client IDs for Google Sign-In (Google Identity Services).
///
/// These are **client IDs, not secrets**: they ship inside every build and are
/// safe to commit. The web client *secret* belongs on the backend only and
/// must never appear in this file.
///
/// All three clients live in Google Cloud project `tuhfatulmuslim-3bb03`
/// (project number 104828246708).
class GoogleAuthConfig {
  const GoogleAuthConfig._();

  /// The **web** ("server") OAuth client.
  ///
  /// This is the audience the ID token is minted for, so it is what the
  /// backend verifies `aud` against. Android's Credential Manager also
  /// *requires* it — without it no ID token is issued at all, on any platform.
  ///
  /// Paste the web client ID here once it exists, or override it per build
  /// with `flutter build --dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: _defaultServerClientId,
  );

  /// TODO(google-auth): create the Web OAuth client in Google Cloud Console
  /// and paste its ID here. Format:
  /// `104828246708-xxxxxxxxxxxxxxxx.apps.googleusercontent.com`.
  static const String _defaultServerClientId = '';

  /// The **iOS** OAuth client. Unused on Android, required on iOS.
  ///
  /// Its reversed form must also be registered as a URL scheme in
  /// `ios/Runner/Info.plist`.
  static const String iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: _defaultIosClientId,
  );

  /// TODO(google-auth): create the iOS OAuth client (bundle ID
  /// `com.tuhfatulmuslim.app`) and paste its ID here.
  static const String _defaultIosClientId = '';

  /// The Android OAuth client, recorded for reference only. The Android SDK
  /// resolves it from the signing certificate + package name, so nothing
  /// passes it explicitly.
  static const String androidClientId =
      '104828246708-sbspq2oe1jbq834bv88ubd1ojkg17kvm.apps.googleusercontent.com';

  /// `true` once [serverClientId] is filled in. While this is `false` the
  /// Google buttons stay hidden rather than failing at tap time.
  static bool get isConfigured => serverClientId.isNotEmpty;

  /// The client ID to hand the iOS SDK, or `null` when unset.
  static String? get iosClientIdOrNull =>
      iosClientId.isEmpty ? null : iosClientId;
}
