import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm.dart';

class PrayerAlarmModel extends PrayerAlarm {
  const PrayerAlarmModel({
    required super.prayerType,
    required super.title,
    required super.timeWindow,
    required super.alarmTime,
    required super.offsetMinutesBefore,
    required super.soundMode,
    required super.ringtoneId,
    required super.ringtoneName,
    required super.isEnabled,
  });

  factory PrayerAlarmModel.fromJson(Map<String, dynamic> json) =>
      PrayerAlarmModel(
        prayerType: json['prayerType'] as String? ?? '',
        title: json['title'] as String? ?? '',
        timeWindow: json['timeWindow'] as String? ?? '',
        alarmTime: json['alarmTime'] as String? ?? '',
        offsetMinutesBefore: json['offsetMinutesBefore'] as int? ?? 0,
        soundMode: json['soundMode'] as String? ?? 'vibrate_and_ring',
        ringtoneId: json['ringtoneId'] as String? ?? '',
        ringtoneName: json['ringtoneName'] as String? ?? '',
        isEnabled: json['isEnabled'] as bool? ?? false,
      );
}
