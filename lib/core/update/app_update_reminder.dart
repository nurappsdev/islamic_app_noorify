import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers a "Later" on the update prompt, so the reminder comes back after
/// [reminderInterval] instead of at every launch.
///
/// The build that was put off is saved with it: a release newer than that one
/// is worth asking about again straight away, so a user who postpones one
/// update is not left unprompted for a later, more important one.
class AppUpdateReminder {
  const AppUpdateReminder._();

  /// How long "Later" silences the prompt for.
  static const reminderInterval = Duration(days: 3);

  static const _snoozedAtKey = 'app_update_snoozed_at';
  static const _snoozedVersionKey = 'app_update_snoozed_version_code';

  /// Records that the user chose "Later" for [versionCode] (the Play version
  /// code of the available update, null when Play did not report one).
  static Future<void> snooze(int? versionCode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      _snoozedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    if (versionCode == null) {
      await preferences.remove(_snoozedVersionKey);
    } else {
      await preferences.setInt(_snoozedVersionKey, versionCode);
    }
  }

  /// Whether the prompt for [versionCode] is still being held back.
  static Future<bool> isSnoozed(int? versionCode) async {
    final preferences = await SharedPreferences.getInstance();
    final snoozedAt = preferences.getInt(_snoozedAtKey);
    if (snoozedAt == null) return false;

    final snoozedVersion = preferences.getInt(_snoozedVersionKey);
    if (versionCode != null &&
        snoozedVersion != null &&
        versionCode > snoozedVersion) {
      return false;
    }

    final snoozedOn = DateTime.fromMillisecondsSinceEpoch(snoozedAt);
    final now = DateTime.now();
    // A clock set backwards (or a stored time from the future) would
    // otherwise hide the prompt indefinitely.
    if (now.isBefore(snoozedOn)) return false;
    return now.isBefore(snoozedOn.add(reminderInterval));
  }

  /// Records a "Later" as though it had been chosen [daysAgo] days ago, so
  /// the three-day rule can be driven from a debug run or a test without
  /// waiting three days.
  @visibleForTesting
  static Future<void> snoozeDaysAgo(double daysAgo, {int? versionCode}) async {
    final preferences = await SharedPreferences.getInstance();
    final microseconds = (Duration.microsecondsPerDay * daysAgo).round();
    await preferences.setInt(
      _snoozedAtKey,
      DateTime.now()
          .subtract(Duration(microseconds: microseconds))
          .millisecondsSinceEpoch,
    );
    if (versionCode == null) {
      await preferences.remove(_snoozedVersionKey);
    } else {
      await preferences.setInt(_snoozedVersionKey, versionCode);
    }
  }

  /// Forgets the postponement, so the next check prompts again.
  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_snoozedAtKey);
    await preferences.remove(_snoozedVersionKey);
  }
}
