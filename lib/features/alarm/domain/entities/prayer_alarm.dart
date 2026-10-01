/// One prayer's alarm as the "Prayers Alarm" tab shows it: the saved settings
/// (see `PrayerAlarmSetting`) worked out against the day's prayer times.
class PrayerAlarm {
  const PrayerAlarm({
    required this.prayerType,
    required this.timeWindow,
    required this.alarmTime,
    required this.offsetMinutesBefore,
    required this.soundMode,
    required this.ringtoneId,
    required this.ringtoneName,
    required this.isEnabled,
    this.ringtoneUrl = '',
  });

  /// `fajr`, `dhuhr`, `asr`, `maghrib`, `isha` or `tahajjud`.
  final String prayerType;

  /// The prayer's time window, e.g. `04:35 PM - 05:15 PM`; empty while the
  /// day's prayer times aren't available.
  final String timeWindow;

  /// When the alarm rings, e.g. `4:10 AM` - the prayer's start minus
  /// [offsetMinutesBefore]; `--:--` while the day's prayer times aren't
  /// available.
  final String alarmTime;
  final int offsetMinutesBefore;

  /// `ring`, `vibrate` or `vibrate_and_ring`.
  final String soundMode;
  final String ringtoneId;
  final String ringtoneName;

  /// The chosen ringtone's audio URL; empty for the bundled default.
  final String ringtoneUrl;
  final bool isEnabled;
}
