import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm.dart';

/// `GET /alarms` — backs the whole "All Alarm" screen: the header countdown
/// and both tabs' lists.
class AlarmDashboard {
  const AlarmDashboard({
    required this.nextAlarmCountdown,
    required this.prayerAlarms,
  });

  /// Already formatted by the server, e.g. "Alarm will be ring in 6 hr 37
  /// min" — accounts for prayer alarms too, unlike the client-computed
  /// fallback in `AllAlarmScreen`.
  final String nextAlarmCountdown;
  final List<PrayerAlarm> prayerAlarms;
}
