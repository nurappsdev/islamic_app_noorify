import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';

/// Which alarms this device should have armed, worked out from the alarms
/// saved on the device. Pure, so the rules are testable on their own;
/// `AlarmScheduler.sync` applies the result to the OS.
class AlarmSyncPlan {
  const AlarmSyncPlan({
    required this.armed,
    required this.skipped,
    required this.retained,
    required this.duplicateTimes,
  });

  /// Alarms to arm, each under its own id.
  final List<AlarmEntry> armed;

  /// Alarm id -> why it must not ring. Each one is disarmed.
  final Map<String, String> skipped;

  /// Alarm ids that are on but whose time can't be worked out right now (a
  /// prayer alarm while the day's prayer times are unavailable). They are left
  /// exactly as they are: neither re-armed nor cancelled.
  final Set<String> retained;

  /// `HH:mm` values that more than one armed alarm shares (they ring back to
  /// back), for the log.
  final List<String> duplicateTimes;

  static String prayerAlarmId(String prayerType) => 'prayer_$prayerType';

  /// What a prayer alarm's notification says. The alarm also rings from a
  /// background isolate that has no access to the app's translations.
  static const _prayerNames = {
    'fajr': 'Fajr',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
    'tahajjud': 'Tahajjud',
  };

  /// [customAlarms] are the user's own alarms and [prayers] the prayer alarms,
  /// each with the time it rings today.
  factory AlarmSyncPlan.build({
    required List<AlarmEntry> customAlarms,
    required List<PrayerAlarm> prayers,
  }) {
    final armed = <AlarmEntry>[];
    final skipped = <String, String>{};
    final retained = <String>{};

    for (final alarm in customAlarms) {
      // Without an id it can't be told apart from another alarm, cancelled,
      // or deleted, so it must never be armed.
      if (alarm.id.isEmpty) continue;
      if (!alarm.enabled) {
        skipped[alarm.id] = 'disabled';
      } else {
        armed.add(alarm);
      }
    }

    for (final prayer in prayers) {
      final id = prayerAlarmId(prayer.prayerType);
      final time = parseClockTime12h(prayer.alarmTime);
      if (!prayer.isEnabled) {
        skipped[id] = 'disabled';
      } else if (time == null) {
        retained.add(id);
      } else {
        armed.add(
          AlarmEntry(
            id: id,
            hour: time.hour,
            minute: time.minute,
            vibrateAndRing: prayer.soundMode == 'vibrate_and_ring',
            vibrate: prayer.soundMode == 'vibrate',
            ring: prayer.soundMode == 'ring',
            enabled: true,
            label: _prayerNames[prayer.prayerType] ?? prayer.prayerType,
            ringtoneId: prayer.ringtoneId,
            ringtoneName: prayer.ringtoneName,
            ringtoneUrl: prayer.ringtoneUrl,
          ),
        );
      }
    }

    final seen = <String>{};
    final duplicates = <String>{};
    for (final alarm in armed) {
      final time =
          '${alarm.hour.toString().padLeft(2, '0')}:'
          '${alarm.minute.toString().padLeft(2, '0')}';
      if (!seen.add(time)) duplicates.add(time);
    }

    return AlarmSyncPlan(
      armed: armed,
      skipped: skipped,
      retained: retained,
      duplicateTimes: duplicates.toList()..sort(),
    );
  }
}
