import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import '../../../core/constants/route_names.dart';
import '../../auth/data/datasources/auth_local_data_source.dart';
import '../../auth/data/services/auth_service.dart';
import '../../onboarding/data/onboarding_preference.dart';
import '../../profile/data/services/profile_service.dart';

/// Resolves the route to land on after splash, including the first-run welcome
/// journey before authentication is considered.
///
/// Once onboarding is done, this always lands on the home screen (bottom
/// bar) — signed in or as a guest, with or without internet — never on sign
/// in. A stored REST access token or an existing Firebase user is used to
/// sync the profile in the background; anyone else just browses as a guest,
/// and individual login-required features prompt sign in themselves (see
/// `requireLogin`/`showLoginRequiredDialog`).
Future<String> resolvePostSplashRoute() async {
  if (!await OnboardingPreference.isCompleted()) {
    return RouteNames.onboardingHadith;
  }

  // Reopening the app with a saved access token -> hydrate the profile.
  if (AuthLocalDataSourceImpl().hasToken) {
    // Show the last cached name immediately, then refresh it from
    // `GET /user/me` in the background.
    ProfileService.instance.hydrateFromCache();
    unawaited(ProfileService.instance.refresh());
    return RouteNames.home;
  }

  if (Firebase.apps.isNotEmpty) {
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        await AuthService.instance.syncLocalProfileFromCurrentUser();
      }
    } catch (_) {
      // No internet, or the sync failed - still a guest, still goes home.
    }
  }
  return RouteNames.home;
}
