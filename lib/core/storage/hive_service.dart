import 'package:hive_flutter/hive_flutter.dart';

/// Central place to open the app's Hive boxes.
///
/// Call [HiveService.init] once during app start-up (before `runApp`).
class HiveService {
  const HiveService._();

  /// Box that holds the authenticated session (auth token, etc.).
  static const String authBox = 'auth_box';

  /// Box that holds the user's custom alarms, one entry per alarm keyed by
  /// its id. The alarms live only on the device.
  static const String alarmsBox = 'alarms_box';

  /// Box that holds the prayer alarm settings, one entry per prayer keyed by
  /// its type (`fajr`, ...).
  static const String prayerAlarmsBox = 'prayer_alarms_box';

  /// Box that holds the cached 99 Names of Allah (each with its full
  /// explanation), one entry per name keyed by its id.
  static const String asmaHusnaBox = 'asma_husna_box';

  /// Box that holds the Home Screen's Zikr counters (Prayer Zikr 1 & 2
  /// progress, and the latest zikr performed). Device-local only, never
  /// synced to the backend.
  static const String zikrBox = 'zikr_box';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(authBox);
    await Hive.openBox<dynamic>(alarmsBox);
    await Hive.openBox<dynamic>(prayerAlarmsBox);
    await Hive.openBox<dynamic>(asmaHusnaBox);
    await Hive.openBox<dynamic>(zikrBox);
    _initialized = true;
  }

  /// Already-opened auth box. Safe to call after [init].
  static Box<dynamic> get auth => Hive.box<dynamic>(authBox);

  /// Already-opened alarms box. Safe to call after [init].
  static Box<dynamic> get alarms => Hive.box<dynamic>(alarmsBox);

  /// Already-opened prayer alarm settings box. Safe to call after [init].
  static Box<dynamic> get prayerAlarms => Hive.box<dynamic>(prayerAlarmsBox);

  /// Already-opened Asma-ul-Husna cache box. Safe to call after [init].
  static Box<dynamic> get asmaHusna => Hive.box<dynamic>(asmaHusnaBox);

  /// Already-opened Zikr counters box. Safe to call after [init].
  static Box<dynamic> get zikr => Hive.box<dynamic>(zikrBox);
}
