import 'package:hive_flutter/hive_flutter.dart';

/// Central place to open the app's Hive boxes.
///
/// Call [HiveService.init] once during app start-up (before `runApp`).
class HiveService {
  const HiveService._();

  /// Box that holds the authenticated session (auth token, etc.).
  static const String authBox = 'auth_box';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(authBox);
    _initialized = true;
  }

  /// Already-opened auth box. Safe to call after [init].
  static Box<dynamic> get auth => Hive.box<dynamic>(authBox);
}
