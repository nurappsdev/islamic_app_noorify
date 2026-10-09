import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the one-time Zikr welcome screen has already been shown
/// on this device. It is intentionally device-scoped, not tied to login.
class ZikrIntroStore {
  const ZikrIntroStore();

  static const _seenKey = 'zikr_intro_seen';

  Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  /// Returns true just once, recording the visit before the intro is drawn.
  Future<bool> takeFirstVisit() async {
    if (await hasSeen()) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
    return true;
  }
}
