import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// This install's identity, for the fields the backend wants alongside an
/// auth request: a stable `deviceId` and the running `appVersion`.
///
/// The ID is a random UUID generated on first use and kept in
/// [SharedPreferences] rather than Hive, so it survives sign-out (the Hive
/// boxes are wiped then) and is tied to the install, not the user. Android's
/// hardware identifiers are deliberately not used: `Build.ID` is not unique
/// per device, and `ANDROID_ID` is no longer exposed by `device_info_plus`.
class DeviceIdentityService {
  DeviceIdentityService._();

  static final DeviceIdentityService instance = DeviceIdentityService._();

  static const String _deviceIdKey = 'device_id';

  String? _cachedDeviceId;
  String? _cachedAppVersion;

  /// A stable identifier for this install. Generated once, then reused.
  ///
  /// Returns `null` only when local storage is unavailable, so callers leave
  /// the field out rather than inventing a value.
  Future<String?> deviceId() async {
    final cached = _cachedDeviceId;
    if (cached != null) return cached;

    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(_deviceIdKey);
      if (id == null || id.isEmpty) {
        id = const Uuid().v4();
        await prefs.setString(_deviceIdKey, id);
      }
      return _cachedDeviceId = id;
    } catch (_) {
      return null;
    }
  }

  /// The running version, as `version+buildNumber` (e.g. `1.0.8+8`) so it
  /// matches what `pubspec.yaml` declares and what the store shows.
  Future<String?> appVersion() async {
    final cached = _cachedAppVersion;
    if (cached != null) return cached;

    try {
      final info = await PackageInfo.fromPlatform();
      final build = info.buildNumber.trim();
      final version = info.version.trim();
      if (version.isEmpty) return null;
      return _cachedAppVersion = build.isEmpty ? version : '$version+$build';
    } catch (_) {
      return null;
    }
  }

  /// Both values at once, since every caller needs the pair.
  Future<({String? deviceId, String? appVersion})> describe() async {
    final results = await Future.wait([deviceId(), appVersion()]);
    return (deviceId: results[0], appVersion: results[1]);
  }

  /// Test seam: clears the memoized values.
  void resetForTest() {
    _cachedDeviceId = null;
    _cachedAppVersion = null;
  }
}
