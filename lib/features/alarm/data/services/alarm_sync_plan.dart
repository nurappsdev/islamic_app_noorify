import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';

/// Which alarms this device should have armed, worked out from what
/// `GET /alarms` returned. Pure, so the rules are testable on their own;
/// `AlarmScheduler.sync` applies the result to the OS.
class AlarmSyncPlan {
  const AlarmSyncPlan({
    required this.armed,
    required this.skipped,
    required this.duplicateTimes,
  });

  /// Alarms to arm, each under its own id.
  final List<AlarmEntry> armed;

  /// Alarm id -> why it must not ring. Each one is disarmed.
  final Map<String, String> skipped;

  /// `HH:mm` values that more than one armed alarm shares (they ring back to
  /// back), for the log.
  final List<String> duplicateTimes;

  static String prayerAlarmId(String prayerType) => 'prayer_$prayerType';

  /// [customAlarms] and [prayers] are the server's lists.
  ///
  /// [userPrayerTypes] are the prayers the user picked on this device in
  /// "Set All Alarm": the server lists every prayer, often pre-enabled, but
  /// only the picked ones may ring here. [ringtoneUrls] maps a ringtone id to
  /// its audio URL for the prayer alarms, which don't carry one themselves.
  factory AlarmSyncPlan.build({
    required List<AlarmEntry> customAlarms,
    required List<PrayerAlarm> prayers,
    required Set<String> userPrayerTypes,
    Map<String, String> ringtoneUrls = const {},
  }) {
    final armed = <AlarmEntry>[];
    final skipped = <String, String>{};

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
      if (!userPrayerTypes.contains(prayer.prayerType)) {
        skipped[id] = 'not selected on this device';
      } else if (!prayer.isEnabled) {
        skipped[id] = 'disabled';
      } else if (time == null) {
        skipped[id] = 'unreadable time "${prayer.alarmTime}"';
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
            label: prayer.title,
            ringtoneId: prayer.ringtoneId,
            ringtoneName: prayer.ringtoneName,
            ringtoneUrl: ringtoneUrls[prayer.ringtoneId] ?? '',
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
      duplicateTimes: duplicates.toList()..sort(),
    );
  }
}
