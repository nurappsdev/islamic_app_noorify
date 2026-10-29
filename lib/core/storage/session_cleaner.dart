import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/core/storage/session_clear_audit.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/amol_day_snapshot_store.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/amol_pending_actions_store.dart';
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
  @visibleForTesting
  static const userPrefKeys = {
    'hadith_completed_ids',
    'quran_last_read',
    'quran_reading_history',
    'quran_bookmarks',
    // Unsent Quran reading time: it must not be credited to the next account.
    'quran_reading_pending',
    // Unsent Amol ticks, and the cached daily checklists they are shown
    // against: both belong to the account that made them. Clearing them is
    // what keeps one account's offline progress from being logged under the
    // next one that signs in on this device.
    AmolPendingActionsStore.key,
    AmolDaySnapshotStore.key,
    // The single-slot cache earlier builds wrote the checklist to.
    'offline_cache_amol_daily_json',
    'offline_cache_amol_daily_at_ms',
    // The user's own Quran playlists and plans, mirrored here from the API as
    // a secondary cache — the next account must not be served them.
    'quran_playlists_v1',
    'quran_saved_plans_v1',
  };

  /// SharedPreferences key prefixes holding per-user progress.
  ///
  /// `offline_cache_` is every `LatestJsonCache` payload — the Home
  /// dashboard, the leaderboard, the Amol checklists — and each one is a
  /// response fetched *for the account that was signed in*. Clearing by
  /// prefix means a cache added later is covered without anyone having to
  /// remember this list; the downloaded content caches (books, Quran text,
  /// Asma-ul-Husna) live in Hive and SQLite, not under this prefix, so they
  /// are untouched.
  @visibleForTesting
  static const userPrefPrefixes = [
    'ebook_last_page_',
    'alarm_dismissed_',
    'offline_cache_',
  ];

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
        if (userPrefKeys.contains(key) ||
            userPrefPrefixes.any(key.startsWith)) {
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

    // Debug-only proof that the wipe above actually landed: every store is
    // read back and reported as Cleared / Not Cleared. Counts and key names
    // only — a stored value never reaches the console.
    if (kDebugMode) {
      final report = await SessionClearAudit.run(
        prefKeys: userPrefKeys,
        prefPrefixes: userPrefPrefixes,
      );
      report.debugLog();
    }
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
