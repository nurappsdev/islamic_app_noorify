import 'package:shared_preferences/shared_preferences.dart';

import 'package:islami_app_noorify/features/alarm/data/services/alarm_log.dart';
import 'package:islami_app_noorify/features/alarm/data/services/alarm_scheduler.dart';

const _migratedKey = 'alarms_on_device_v1';

/// Alarms used to be saved on the server and armed from its list; they now
/// live only on the device. The first time this version runs, everything the
/// old one left behind is removed: the cached alarm list (whose entries can
/// include alarms already deleted on the server) and every OS alarm armed
/// from server data. The user then starts from the alarms saved on the device.
Future<void> migrateToOnDeviceAlarms() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedKey) ?? false) return;
    await AlarmScheduler.cancelAllAlarms(
      reason: 'alarms moved from the server to this device',
    );
    await prefs.setBool(_migratedKey, true);
  } catch (e) {
    await AlarmLog.record('migrate', status: 'failed', detail: '$e');
  }
}
