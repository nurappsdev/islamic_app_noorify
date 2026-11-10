import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/core/storage/session_clear_audit.dart';
import 'package:tuhfatul_muslim/core/storage/session_cleaner.dart';
import 'package:tuhfatul_muslim/features/hadith/data/hadith_database.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';

/// What logout must wipe: the session itself, the account's progress, and
/// every API response cached for the account that was signed in.
const _sessionPrefs = {
  'quran_last_read': '2:255',
  'quran_reading_history': '[]',
  'quran_bookmarks': '[]',
  'quran_reading_pending': '[]',
  'hadith_completed_ids': '["a"]',
  'quran_playlists_v1': '[{"id":"pl_1"}]',
  'quran_saved_plans_v1': '[{"id":"p1"}]',
  'offline_cache_home_dashboard_json': '{"points":42}',
  'offline_cache_leaderboard_daily_json': '{"me":1}',
  'offline_cache_amol_day_snapshots': '{}',
  'ebook_last_page_riyad': 12,
  'alarm_dismissed_fajr': '2026-10-29',
};

/// What logout must leave alone: device settings and downloaded content.
const _devicePrefs = {
  'app_dark_theme_enabled': true,
  'app_language': 'bn',
  'device_id': 'device-1',
  'quran_intro_seen': true,
  'welcome_onboarding_completed': true,
  'quran_font_size_multiplier': 1.2,
  'hadith_show_arabic': true,
  'quran_internal_content_v1': '{"surahs":[]}',
  'prayer_times_json': '{"timings":{}}',
  'widget_location': 'Dhaka',
};

void main() {
  late Directory tmp;
  late Directory dbDir;

  setUpAll(() async {
    // Without this the hadith database is unreadable in tests and the audit
    // can only report UNKNOWN for it; with it, the SQLite check is real.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dbDir = await Directory.systemTemp.createTemp('logout_session_clear_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
  });

  tearDownAll(() async {
    await (await HadithDatabase().open()).close();
    dbDir.deleteSync(recursive: true);
  });

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('logout_session_clear');
    Hive.init(tmp.path);
    await Hive.openBox<dynamic>(HiveService.authBox);
    await Hive.openBox<dynamic>(HiveService.alarmsBox);
    await Hive.openBox<dynamic>(HiveService.prayerAlarmsBox);

    SharedPreferences.setMockInitialValues({..._sessionPrefs, ..._devicePrefs});

    // A signed-in session, exactly as sign-in and the refresh interceptor
    // leave it: access token, refresh token, its cookie name, cached profile.
    await HiveService.auth.putAll({
      'auth_token': 'access-token',
      'refresh_token': 'refresh-token',
      'refresh_cookie_name': 'refreshToken',
      'profile_data': {'name': 'Someone'},
    });
    await HiveService.alarms.put('a1', {'id': 'a1'});
    await HiveService.prayerAlarms.put('fajr', {'enabled': true});

    profileNameNotifier.value = 'Someone';
    profilePhotoUrlNotifier.value = 'https://example.com/a.png';
    profilePhotoBase64Notifier.value = 'base64';
    skipAuthGateNotifier.value = true;
    unreadNotificationCountNotifier.value = 3;
  });

  tearDown(() async {
    await Hive.close();
    tmp.deleteSync(recursive: true);
  });

  /// One saved hadith, the shape [HadithDatabase.clearUserData] empties.
  Future<void> saveHadithBookmark() async {
    final db = await HadithDatabase().open();
    await db.insert('hadith_bookmarks', {
      'book_slug': 'riyad',
      'hadith_no': '1',
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  test('clears the session, the account cache and nothing else', () async {
    await saveHadithBookmark();
    expect(await HadithDatabase().userDataRowCount(), greaterThan(0));

    await SessionCleaner.clearUserData();

    expect(await HadithDatabase().userDataRowCount(), 0);

    expect(HiveService.auth.keys, isEmpty, reason: 'tokens + cached profile');
    expect(HiveService.alarms.keys, isEmpty);
    expect(HiveService.prayerAlarms.keys, isEmpty);

    final prefs = await SharedPreferences.getInstance();
    for (final key in _sessionPrefs.keys) {
      expect(prefs.containsKey(key), isFalse, reason: '$key must be cleared');
    }
    for (final entry in _devicePrefs.entries) {
      expect(prefs.get(entry.key), entry.value, reason: '${entry.key} is kept');
    }

    expect(profileNameNotifier.value, isNull);
    expect(profilePhotoUrlNotifier.value, isNull);
    expect(profilePhotoBase64Notifier.value, isNull);
    expect(skipAuthGateNotifier.value, isFalse);
    expect(unreadNotificationCountNotifier.value, 0);
  });

  group('the post-logout audit', () {
    test('reports every store clear once the wipe has run', () async {
      await saveHadithBookmark();
      await SessionCleaner.clearUserData();

      final report = await SessionClearAudit.run(
        prefKeys: SessionCleaner.userPrefKeys,
        prefPrefixes: SessionCleaner.userPrefPrefixes,
      );

      expect(report.isComplete, isTrue);
      final failed = report.checks
          .where((c) => c.status == SessionClearStatus.notCleared)
          .map((c) => c.store);
      expect(failed, isEmpty);
    });

    test('catches a store that still holds session data', () async {
      await SessionCleaner.clearUserData();
      // Exactly the leak this audit exists to catch: an API response cached
      // for the account that just signed out.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_cache_home_dashboard_json', '{}');

      final report = await SessionClearAudit.run(
        prefKeys: SessionCleaner.userPrefKeys,
        prefPrefixes: SessionCleaner.userPrefPrefixes,
      );

      expect(report.isComplete, isFalse);
      final failed = report.checks.firstWhere(
        (c) => c.status == SessionClearStatus.notCleared,
      );
      expect(failed.detail, contains('offline_cache_home_dashboard_json'));
    });

    test('never puts a stored value in its detail text', () async {
      await HiveService.auth.put('auth_token', 'super-secret-token');

      final report = await SessionClearAudit.run(
        prefKeys: SessionCleaner.userPrefKeys,
        prefPrefixes: SessionCleaner.userPrefPrefixes,
      );

      final details = report.checks.map((c) => c.detail ?? '').join(' ');
      expect(details, contains('auth_token')); // the key name is fine
      expect(details, isNot(contains('super-secret-token')));
    });
  });
}
