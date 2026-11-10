import 'package:shared_preferences/shared_preferences.dart';

/// Records whether the welcome journey has already been completed or skipped.
class OnboardingPreference {
  const OnboardingPreference._();

  static const _completedKey = 'welcome_onboarding_completed';

  static Future<bool> isCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_completedKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_completedKey, true);
  }
}
