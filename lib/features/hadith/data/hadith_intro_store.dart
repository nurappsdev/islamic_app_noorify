import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the Hadith intro ("Let's Get Start") screen has already
/// been shown on this device, so it appears only the first time Hadith is
/// opened. Kept in shared preferences, so it survives restarts and logging
/// out.
class HadithIntroStore {
  const HadithIntroStore();

  static const _seenKey = 'hadith_intro_seen';

  Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  /// True exactly once: the first time it is called it records that the intro
  /// is being shown and returns true; every later call returns false.
  Future<bool> takeFirstVisit() async {
    if (await hasSeen()) return false;
    await markSeen();
    return true;
  }
}
