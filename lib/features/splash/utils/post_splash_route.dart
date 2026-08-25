import 'package:firebase_core/firebase_core.dart';

import '../../../core/constants/route_names.dart';
import '../../auth/data/services/auth_service.dart';

/// Resolves the route to land on once the splash/onboarding flow is done.
///
/// Guests open sign in. When a Firebase user exists we sync the local profile
/// first, then admins land on the admin dashboard and everyone else on home.
Future<String> resolvePostSplashRoute() async {
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
