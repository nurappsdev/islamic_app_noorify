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
/// If a REST access token is stored locally (Hive) the user is already signed
/// in, so we go straight to the home screen (bottom bar). Otherwise: guests
/// open sign in, and an existing Firebase user lands on home after a profile
/// sync.
Future<String> resolvePostSplashRoute() async {
  if (!await OnboardingPreference.isCompleted()) {
    return RouteNames.onboardingHadith;
  }

  // Reopening the app with a saved access token -> straight to home.
  if (AuthLocalDataSourceImpl().hasToken) {
    // Show the last cached name immediately, then refresh it from
    // `GET /user/me` in the background.
    ProfileService.instance.hydrateFromCache();
    unawaited(ProfileService.instance.refresh());
    return RouteNames.home;
  }

  if (Firebase.apps.isEmpty) {
    return RouteNames.signIn;
  }
  try {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      await AuthService.instance.syncLocalProfileFromCurrentUser();
      return RouteNames.home;
    }
    return RouteNames.signIn;
  } catch (_) {
    return RouteNames.signIn;
  }
}
