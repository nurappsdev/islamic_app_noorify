import 'package:islami_app_noorify/features/alarm/data/models/prayer_alarm_model.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_dashboard.dart';

class AlarmDashboardModel extends AlarmDashboard {
  const AlarmDashboardModel({
    required super.nextAlarmCountdown,
    required super.prayerAlarms,
  });

  factory AlarmDashboardModel.fromJson(Map<String, dynamic> json) {
    final prayerAlarms = json['prayerAlarms'];
    return AlarmDashboardModel(
      nextAlarmCountdown: json['nextAlarmCountdown'] as String? ?? '',
      prayerAlarms: prayerAlarms is List
          ? prayerAlarms
                .whereType<Map<String, dynamic>>()
                .map(PrayerAlarmModel.fromJson)
                .toList()
          : const [],
    );
  }
}
