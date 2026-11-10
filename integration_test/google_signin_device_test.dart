// A diagnostic that runs on a real Android device:
//
//   flutter test integration_test/google_signin_device_test.dart -d <deviceId>
//
// It asks Google Play Services for an ID token and reports exactly what comes
// back, so a configuration problem can be told apart from a backend one
// without tapping through the app by hand.
//
// It is not part of the unit suite (`flutter test` only picks up `test/`), so
// it never runs in CI.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tuhfatul_muslim/core/services/google_auth_config.dart';
import 'package:tuhfatul_muslim/features/auth/data/services/google_auth_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reports how Google Sign-In is configured on this device', (
    tester,
  ) async {
    debugPrint('=== GOOGLE SIGN-IN DEVICE DIAGNOSTIC ===');
    debugPrint('serverClientId : ${GoogleAuthConfig.serverClientId}');
    debugPrint('isConfigured   : ${GoogleAuthConfig.isConfigured}');

    expect(
      GoogleAuthConfig.isConfigured,
      isTrue,
      reason: 'No web server client ID is compiled into this build.',
    );

    // 1. Initialization: fails when the SDK itself cannot be set up.
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: GoogleAuthConfig.serverClientId,
      );
      debugPrint('initialize()   : OK');
    } catch (e) {
      debugPrint('initialize()   : FAILED -> $e');
      rethrow;
    }

    debugPrint('supportsAuthenticate: '
        '${GoogleSignIn.instance.supportsAuthenticate()}');

    // 2. A silent attempt. This never shows UI, so it either returns an
    //    already-granted account or null -- but a *configuration* problem
    //    still surfaces here as an exception, which is what we are after.
    try {
      final account = await GoogleSignIn.instance
          .attemptLightweightAuthentication()
          ?.timeout(const Duration(seconds: 25));
      if (account == null) {
        debugPrint('lightweight    : no cached account (not an error)');
      } else {
        final idToken = account.authentication.idToken;
        debugPrint('lightweight    : signed in as ${account.email}');
        debugPrint('idToken        : '
            '${idToken == null ? "NULL" : "${idToken.length} chars"}');
      }
    } on GoogleSignInException catch (e) {
      debugPrint('lightweight    : GoogleSignInException');
      debugPrint('  code         : ${e.code}');
      debugPrint('  description  : ${e.description}');
      debugPrint('  details      : ${e.details}');
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        debugPrint(
          '  >>> DEVELOPER_ERROR: this build\'s signing certificate has no '
          'matching Android OAuth client in the Cloud project.',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('lightweight    : $e');
      rethrow;
    }

    debugPrint('=== END DIAGNOSTIC ===');
  });

  testWidgets('the service wrapper surfaces a usable error', (tester) async {
    // Mirrors what the Sign-In button does, minus the account picker.
    try {
      final result = await GoogleAuthService.instance.signIn().timeout(
        const Duration(seconds: 30),
      );
      debugPrint('signIn() OK: ${result.email} / '
          'idToken ${result.idToken.length} chars');
    } on GoogleSignInException catch (e) {
      debugPrint('signIn() GoogleSignInException code=${e.code} '
          'description=${e.description}');
    } catch (e) {
      debugPrint('signIn() failed: $e');
    }
  });
}
