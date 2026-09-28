import 'package:islami_app_noorify/features/alarm/data/services/alarm_log.dart';
import 'package:islami_app_noorify/features/alarm/data/services/alarm_scheduler.dart';
import 'package:islami_app_noorify/features/alarm/data/services/alarm_sync_plan.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_dashboard.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_alarm_dashboard.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_ringtones.dart';

/// Arms this device's alarms from a freshly fetched [dashboard] and disarms
/// everything else (see [AlarmScheduler.sync]).
///
/// The server list is the only source: alarms are never generated locally.
/// Call only with a dashboard that loaded successfully - a failed request
/// (offline, signed out) must leave the current schedule alone.
Future<void> syncDeviceAlarms(
  AlarmDashboard dashboard, {
  GetRingtones? getRingtones,
}) async {
  try {
    final ringtoneUrls = <String, String>{};
    final catalog = await getRingtones?.call();
    catalog?.fold((_) {}, (list) {
      for (final ringtone in list) {
        ringtoneUrls[ringtone.id] = ringtone.audioUrl;
      }
    });
    await AlarmScheduler.sync(
      AlarmSyncPlan.build(
        customAlarms: dashboard.customAlarms,
        prayers: dashboard.prayerAlarms,
        userPrayerTypes: await AlarmScheduler.userPrayerAlarmTypes(),
        ringtoneUrls: ringtoneUrls,
      ),
    );
  } catch (e) {
    // Best-effort: the next successful load syncs again.
    await AlarmLog.record('sync', status: 'failed', detail: '$e');
  }
}

/// Fetches the dashboard and syncs from it. Run at app start for a signed-in
/// user, so an alarm the server no longer lists stops ringing straight away
/// instead of waiting for the alarm screen to be opened.
Future<void> syncDeviceAlarmsFromServer({
  required GetAlarmDashboard getAlarmDashboard,
  GetRingtones? getRingtones,
}) async {
  final result = await getAlarmDashboard();
  await result.fold(
    (failure) => AlarmLog.record(
      'sync',
      status: 'skipped',
      detail: 'could not load alarms: ${failure.message}',
    ),
    (dashboard) => syncDeviceAlarms(dashboard, getRingtones: getRingtones),
  );
}
