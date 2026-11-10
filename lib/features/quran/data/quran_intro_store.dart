import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the "Read Quran" intro screen has already been shown on
/// this device, so it appears only the first time Quran is opened.
class QuranIntroStore {
  const QuranIntroStore();

  static const _seenKey = 'quran_intro_seen';

  /// True exactly once: the first call records the intro as shown and returns
  /// true; every later call returns false.
  Future<bool> takeFirstVisit() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seenKey) ?? false) return false;
    await prefs.setBool(_seenKey, true);
    return true;
  }
}
