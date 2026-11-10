// Drives the whole Google Sign-In flow on a real device, end to end:
// account picker -> Google ID token -> POST /auth/google -> app session.
//
//   flutter test integration_test/google_signin_flow_test.dart -d <deviceId>
//
// The account picker is system UI, so a person (or `adb shell input tap`)
// has to choose an account while this runs. Every step is printed, so the
// first failing one is obvious.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tuhfatul_muslim/core/services/api_constants.dart';
import 'package:tuhfatul_muslim/core/services/device_identity_service.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/repositories/account_repository_impl.dart';
import 'package:tuhfatul_muslim/features/auth/data/services/google_auth_service.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/google_sign_in_params.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full Google Sign-In flow against the staging backend', (
    tester,
  ) async {
    debugPrint('### baseUrl: ${ApiConstants.baseUrl}');
    debugPrint('### endpoint: ${ApiConstants.googleSignInEndPoint}');

    final identity = await DeviceIdentityService.instance.describe();
    debugPrint('### deviceId  : ${identity.deviceId}');
    debugPrint('### appVersion: ${identity.appVersion}');

    debugPrint('### STEP 1: opening the Google account picker...');
    late final GoogleAuthResult google;
    try {
      google = await GoogleAuthService.instance.signIn().timeout(
        const Duration(seconds: 150),
      );
    } on GoogleSignInException catch (e) {
      debugPrint('### STEP 1 FAILED: code=${e.code} desc=${e.description}');
      fail('Google sign-in failed: ${e.code}');
    } catch (e) {
      debugPrint('### STEP 1 FAILED: $e');
      fail('Google sign-in failed: $e');
    }

    debugPrint('### STEP 1 OK');
    debugPrint('###   email    : ${google.email}');
    debugPrint('###   name     : ${google.displayName}');
    debugPrint('###   idToken  : ${google.idToken.length} chars');
    expect(google.idToken, isNotEmpty);

    debugPrint('### STEP 2: POST ${ApiConstants.googleSignInEndPoint} ...');
    final outcome = await AccountRepositoryImpl(AuthRemoteDataSourceImpl())
        .googleSignIn(
          GoogleSignInParams(
            idToken: google.idToken,
            email: google.email,
            displayName: google.displayName,
            photoUrl: google.photoUrl,
          ),
        );

    outcome.fold(
      (failure) {
        debugPrint('### STEP 2 FAILED: ${failure.runtimeType} '
            '(${failure.statusCode}) -> ${failure.rawMessage}');
        fail('Backend rejected the token: ${failure.rawMessage}');
      },
      (user) {
        debugPrint('### STEP 2 OK');
        debugPrint('###   user id : ${user.id}');
        debugPrint('###   name    : ${user.name}');
        debugPrint('###   email   : ${user.email}');
      },
    );

    debugPrint('### STEP 3: session token stored?');
    final repo = AccountRepositoryImpl(AuthRemoteDataSourceImpl());
    debugPrint('###   isSignedIn: ${repo.isSignedIn}');
    debugPrint('###   token len : ${repo.authToken?.length}');
    expect(repo.isSignedIn, isTrue);

    debugPrint('### FLOW COMPLETE');
  });
}
