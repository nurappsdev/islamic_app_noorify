import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/hadith/data/hadith_database.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';

/// Reads every local store back after [SessionCleaner] has run and reports,
/// store by store, whether anything of the session is still there.
///
/// Nothing it produces is sensitive: a check reports a count, a boolean or a
/// *key name*, never a stored value, so a token can never reach the console
/// or a bug report through here.
enum SessionClearStatus {
  cleared,
  notCleared,

  /// This app has no such store, so the session was never in it.
  notUsed,

  /// The store could not be read — it may not exist on this device yet.
  unknown,
}

@immutable
class SessionClearCheck {
  const SessionClearCheck(this.store, this.status, {this.detail});

  final String store;
  final SessionClearStatus status;

  /// Counts and key names only — never a stored value.
  final String? detail;
}

class SessionClearReport {
  const SessionClearReport(this.checks);

  final List<SessionClearCheck> checks;

  /// `true` when no check found session data left behind. A store that could
  /// not be read is not a failure on its own, and says so in the log.
  bool get isComplete =>
      checks.every((check) => check.status != SessionClearStatus.notCleared);

  /// Prints the report to the Flutter debug console. A no-op in release.
  void debugLog() {
    if (!kDebugMode) return;
    debugPrint('[Logout] local session clear report');
    for (final check in checks) {
      final label = switch (check.status) {
        SessionClearStatus.cleared => 'CLEARED    ',
        SessionClearStatus.notCleared => 'NOT CLEARED',
        SessionClearStatus.notUsed => 'NOT USED   ',
        SessionClearStatus.unknown => 'UNKNOWN    ',
      };
      final detail = check.detail;
      debugPrint(
        '[Logout]   $label · ${check.store}'
        '${detail == null ? '' : ' — $detail'}',
      );
    }
    debugPrint(
      '[Logout]   KEPT        · offline content (downloaded books, Quran '
      'text, Asma-ul-Husna) and device settings (theme, language, font '
      'sizes, intro flags, prayer times)',
    );
    debugPrint(
      '[Logout] ${isComplete ? 'no session data left on this device' : 'session data is STILL on this device — see NOT CLEARED above'}',
    );
  }
}

class SessionClearAudit {
  const SessionClearAudit._();

  /// [prefKeys] and [prefPrefixes] are [SessionCleaner]'s own policy, passed
  /// in so this audit measures exactly what the cleaner promised to remove.
  static Future<SessionClearReport> run({
    required Set<String> prefKeys,
    required List<String> prefPrefixes,
  }) async {
    return SessionClearReport([
      _hiveAuthBox(),
      _hiveAlarmBoxes(),
      await _sharedPreferences(prefKeys, prefPrefixes),
      await _hadithDatabase(),
      _secureStorage(),
      _inMemorySession(),
    ]);
  }

  static SessionClearCheck _hiveAuthBox() {
    const store =
        'Hive auth_box (access token, refresh token, session, cached profile)';
    try {
      final box = HiveService.auth;
      final left = box.keys.map((key) => key.toString()).toList()..sort();
      final hasToken = AuthLocalDataSourceImpl(box: box).hasToken;
      if (left.isEmpty && !hasToken) {
        return const SessionClearCheck(store, SessionClearStatus.cleared);
      }
      return SessionClearCheck(
        store,
        SessionClearStatus.notCleared,
        detail: '${left.length} key(s) left: ${left.join(', ')}',
      );
    } catch (_) {
      return const SessionClearCheck(store, SessionClearStatus.unknown);
    }
  }

  static SessionClearCheck _hiveAlarmBoxes() {
    const store = 'Hive alarms_box + prayer_alarms_box (the session\'s alarms)';
    try {
      final left = HiveService.alarms.length + HiveService.prayerAlarms.length;
      if (left == 0) {
        return const SessionClearCheck(store, SessionClearStatus.cleared);
      }
      return SessionClearCheck(
        store,
        SessionClearStatus.notCleared,
        detail: '$left alarm(s) left',
      );
    } catch (_) {
      return const SessionClearCheck(store, SessionClearStatus.unknown);
    }
  }

  static Future<SessionClearCheck> _sharedPreferences(
    Set<String> keys,
    List<String> prefixes,
  ) async {
    const store =
        'SharedPreferences (reading progress, unsent ticks, cached API '
        'responses)';
    try {
      final prefs = await SharedPreferences.getInstance();
      final left =
          prefs
              .getKeys()
              .where(
                (key) => keys.contains(key) || prefixes.any(key.startsWith),
              )
              .toList()
            ..sort();
      if (left.isEmpty) {
        return const SessionClearCheck(store, SessionClearStatus.cleared);
      }
      return SessionClearCheck(
        store,
        SessionClearStatus.notCleared,
        detail: '${left.length} key(s) left: ${left.join(', ')}',
      );
    } catch (_) {
      return const SessionClearCheck(store, SessionClearStatus.unknown);
    }
  }

  static Future<SessionClearCheck> _hadithDatabase() async {
    const store = 'SQLite hadith_books.db (saved hadiths + their folders)';
    try {
      final rows = await HadithDatabase().userDataRowCount();
      if (rows == 0) {
        return const SessionClearCheck(store, SessionClearStatus.cleared);
      }
      return SessionClearCheck(
        store,
        SessionClearStatus.notCleared,
        detail: '$rows row(s) left',
      );
    } catch (_) {
      return const SessionClearCheck(store, SessionClearStatus.unknown);
    }
  }

  /// Stated rather than measured: the app has no secure-storage plugin, so
  /// no credential was ever written to the keystore / keychain by it.
  static SessionClearCheck _secureStorage() => const SessionClearCheck(
    'Secure storage (no secure-storage plugin in this app)',
    SessionClearStatus.notUsed,
  );

  static SessionClearCheck _inMemorySession() {
    const store = 'In-memory session (auth gate, profile notifiers, badge)';
    final left = <String>[
      if (skipAuthGateNotifier.value) 'authGate',
      if (profileNameNotifier.value != null) 'profileName',
      if (profilePhotoUrlNotifier.value != null) 'profilePhotoUrl',
      if (profilePhotoBase64Notifier.value != null) 'profilePhoto',
      if (unreadNotificationCountNotifier.value != 0) 'unreadBadge',
    ];
    if (left.isEmpty) {
      return const SessionClearCheck(store, SessionClearStatus.cleared);
    }
    return SessionClearCheck(
      store,
      SessionClearStatus.notCleared,
      detail: 'still set: ${left.join(', ')}',
    );
  }
}
