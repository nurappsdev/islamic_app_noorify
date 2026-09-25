import 'package:shared_preferences/shared_preferences.dart';

import 'package:islami_app_noorify/core/storage/hive_service.dart';
import 'package:islami_app_noorify/features/alarm/data/services/alarm_scheduler.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_database.dart';
import 'package:islami_app_noorify/shared/services/app_globals.dart';

/// Wipes everything that belongs to the signed-in user, so the next login
/// (the same account or another) starts from a clean slate and only loads its
/// own data. Device-level preferences (theme, language, font sizes, intro
/// screens) and shared content caches (Asma-ul-Husna, downloaded books) are
/// kept — they aren't tied to an account.
class SessionCleaner {
  const SessionCleaner._();

  /// Exact SharedPreferences keys holding per-user progress.
  static const _userPrefKeys = {
    'hadith_completed_ids',
    'quran_last_read',
    'quran_reading_history',
    'quran_bookmarks',
  };

  /// SharedPreferences key prefixes holding per-user progress.
  static const _userPrefPrefixes = ['ebook_last_page_', 'alarm_dismissed_'];

  static Future<void> clearUserData() async {
    // Each step is independent: one failing must not leave the rest behind.
    await _safe(AlarmScheduler.cancelAllAlarms);
    await _safe(() async {
      // Token and the cached profile both live in the auth box.
      await HiveService.auth.clear();
    });
    await _safe(HadithDatabase().clearUserData);
    await _safe(() async {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().toList()) {
        if (_userPrefKeys.contains(key) ||
            _userPrefPrefixes.any(key.startsWith)) {
          await prefs.remove(key);
        }
      }
    });

    profileNameNotifier.value = null;
    profilePhotoUrlNotifier.value = null;
    profilePhotoBase64Notifier.value = null;
    skipAuthGateNotifier.value = false;
  }

  static Future<void> _safe(Future<void> Function() step) async {
    try {
      await step();
    } catch (_) {}
  }
}
