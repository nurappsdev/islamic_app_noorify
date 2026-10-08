import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/features/alarm/data/services/alarm_scheduler.dart';
import 'package:tuhfatul_muslim/features/hadith/data/hadith_database.dart';
import 'package:tuhfatul_muslim/features/notifications/data/services/notification_badge_service.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';

/// Wipes everything that belongs to the current session, so the next one —
/// Guest or another account — starts from a clean slate and never inherits
/// what came before it. Device-level preferences (theme, language, font
/// sizes, intro screens) and shared content caches (Asma-ul-Husna, downloaded
/// books) are kept — they aren't tied to a session.
///
/// Alarms are device-local and not tied to an *account* the way the cached
/// profile or reading progress are, but they must still never cross a
/// Guest/signed-in boundary (see [clearGuestAlarms] and [clearUserData]):
/// without this, alarms created as a Guest would stay armed and visible after
/// someone signs in, and a signed-in user's alarms would leak into Guest mode
/// after signing out.
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

  /// Call right after sign-out, before returning to Guest mode.
  static Future<void> clearUserData() async {
    // Each step is independent: one failing must not leave the rest behind.
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
    // Cancels every scheduled OS alarm/notification for the account that was
    // signed in (prayer and custom alike) and clears their Hive settings —
    // not just the Hive data, so nothing left armed can still ring once
    // Guest mode (or a different account) is active.
    await _safe(() => AlarmScheduler.cancelAllAlarms(reason: 'signed out'));

    profileNameNotifier.value = null;
    profilePhotoUrlNotifier.value = null;
    profilePhotoBase64Notifier.value = null;
    skipAuthGateNotifier.value = false;
    NotificationBadgeService.instance.reset();
  }

  /// Call right after a Guest successfully signs in or registers (i.e. a
  /// token was just cached) — before that, since this is a new session, any
  /// alarm found is necessarily something created in Guest mode. Cancels its
  /// OS schedule/notifications too, the same way [clearUserData] does on the
  /// way out, so the newly signed-in account starts with no alarms at all.
  static Future<void> clearGuestAlarms() async {
    await _safe(
      () => AlarmScheduler.cancelAllAlarms(
        reason: 'signed in — clearing guest alarms',
      ),
    );
  }

  static Future<void> _safe(Future<void> Function() step) async {
    try {
      await step();
    } catch (_) {}
  }
}
