/// One prayer's alarm settings, as returned by `GET /alarms`'s
/// `prayerAlarms` list.
class PrayerAlarm {
  const PrayerAlarm({
    required this.prayerType,
    required this.title,
    required this.timeWindow,
    required this.alarmTime,
    required this.offsetMinutesBefore,
    required this.soundMode,
    required this.ringtoneId,
    required this.ringtoneName,
    required this.isEnabled,
  });

  /// e.g. `fajr`, `dhuhr`, `asr`, `maghrib`, `isha`, `tahajjud`.
  final String prayerType;
  final String title;

  /// e.g. `04:35 PM - 05:15 PM`.
  final String timeWindow;

  /// e.g. `04:10 AM` — 12-hour clock, already formatted by the server.
  final String alarmTime;
  final int offsetMinutesBefore;
  final String soundMode;
  final String ringtoneId;
  final String ringtoneName;
  final bool isEnabled;
}
