import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm_setting.dart';

class PrayerAlarmSettingModel extends PrayerAlarmSetting {
  const PrayerAlarmSettingModel({
    required super.prayerType,
    super.enabled,
    super.offsetMinutesBefore,
    super.soundMode,
    super.ringtoneId,
    super.ringtoneName,
    super.ringtoneUrl,
  });

  factory PrayerAlarmSettingModel.fromEntity(PrayerAlarmSetting setting) =>
      PrayerAlarmSettingModel(
        prayerType: setting.prayerType,
        enabled: setting.enabled,
        offsetMinutesBefore: setting.offsetMinutesBefore,
        soundMode: setting.soundMode,
        ringtoneId: setting.ringtoneId,
        ringtoneName: setting.ringtoneName,
        ringtoneUrl: setting.ringtoneUrl,
      );

  factory PrayerAlarmSettingModel.fromJson(Map<String, dynamic> json) =>
      PrayerAlarmSettingModel(
        prayerType: json['prayerType'] as String,
        enabled: json['enabled'] as bool? ?? false,
        offsetMinutesBefore: json['offsetMinutesBefore'] as int? ?? 0,
        soundMode:
            json['soundMode'] as String? ?? PrayerAlarmSetting.defaultSoundMode,
        ringtoneId:
            json['ringtoneId'] as String? ??
            PrayerAlarmSetting.defaultRingtoneId,
        ringtoneName:
            json['ringtoneName'] as String? ??
            PrayerAlarmSetting.defaultRingtoneName,
        ringtoneUrl: json['ringtoneUrl'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'prayerType': prayerType,
    'enabled': enabled,
    'offsetMinutesBefore': offsetMinutesBefore,
    'soundMode': soundMode,
    'ringtoneId': ringtoneId,
    'ringtoneName': ringtoneName,
    'ringtoneUrl': ringtoneUrl,
  };
}
