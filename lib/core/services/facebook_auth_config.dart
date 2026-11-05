/// Client-side identifiers for Facebook Login.
///
/// Like [GoogleAuthConfig] these are **not secrets**: both values ship inside
/// every build (the native SDK reads the same pair from
/// `android/app/src/main/res/values/strings.xml`) and are safe to commit. The
/// Facebook **App Secret** belongs to the Node backend only and must never
/// appear in this file or in any resource the app ships.
///
/// Facebook app: `Tuhfatul Muslim`, App ID `1693801695699739`.
class FacebookAuthConfig {
  const FacebookAuthConfig._();

  /// The Facebook App ID. Keep this in step with `facebook_app_id` in
  /// `strings.xml` — the native SDK reads that resource, this constant is
  /// what Dart-side code checks and what the backend verifies tokens against.
  static const String appId = String.fromEnvironment(
    'FACEBOOK_APP_ID',
    defaultValue: _defaultAppId,
  );

  static const String _defaultAppId = '1693801695699739';

  /// The Client Token, recorded for reference. The native SDK takes it from
  /// `facebook_client_token` in `strings.xml`; nothing in Dart passes it.
  static const String clientToken = String.fromEnvironment(
    'FACEBOOK_CLIENT_TOKEN',
    defaultValue: _defaultClientToken,
  );

  static const String _defaultClientToken = 'af1776f2d60505e3a28d70f17282fc13';

  /// The permissions requested at login. Kept to the two that need no App
  /// Review, so the flow works for any user from day one.
  static const List<String> loginPermissions = ['email', 'public_profile'];

  /// The Graph fields fetched for the signed-in user. Only used to prefill
  /// the UI — the backend re-reads everything it trusts from the token.
  static const String graphUserFields = 'id,name,email,picture.width(400)';

  /// `true` once [appId] is filled in. While this is `false` the Facebook
  /// button must not attempt a login.
  static bool get isConfigured => appId.isNotEmpty;
}
