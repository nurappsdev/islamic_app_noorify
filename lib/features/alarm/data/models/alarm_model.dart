import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';

class AlarmModel extends AlarmEntry {
  const AlarmModel({
    required super.id,
    required super.hour,
    required super.minute,
    required super.vibrateAndRing,
    required super.vibrate,
    required super.ring,
    required super.enabled,
    super.label,
    super.ringtoneId,
    super.ringtoneName,
    super.ringtoneUrl,
  });

  factory AlarmModel.fromEntity(AlarmEntry entry) => AlarmModel(
    id: entry.id,
    hour: entry.hour,
    minute: entry.minute,
    vibrateAndRing: entry.vibrateAndRing,
    vibrate: entry.vibrate,
    ring: entry.ring,
    enabled: entry.enabled,
    label: entry.label,
    ringtoneId: entry.ringtoneId,
    ringtoneName: entry.ringtoneName,
    ringtoneUrl: entry.ringtoneUrl,
  );

  factory AlarmModel.fromJson(Map<String, dynamic> json) => AlarmModel(
    id: json['id'] as String,
    hour: json['hour'] as int,
    minute: json['minute'] as int,
    vibrateAndRing: json['vibrateAndRing'] as bool? ?? false,
    vibrate: json['vibrate'] as bool? ?? false,
    ring: json['ring'] as bool? ?? false,
    enabled: json['enabled'] as bool? ?? true,
    label: json['label'] as String? ?? '',
    ringtoneId: json['ringtoneId'] as String? ?? AlarmEntry.defaultRingtoneId,
    ringtoneName:
        json['ringtoneName'] as String? ?? AlarmEntry.defaultRingtoneName,
    ringtoneUrl: json['ringtoneUrl'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'vibrateAndRing': vibrateAndRing,
    'vibrate': vibrate,
    'ring': ring,
    'enabled': enabled,
    'label': label,
    'ringtoneId': ringtoneId,
    'ringtoneName': ringtoneName,
    'ringtoneUrl': ringtoneUrl,
  };
}
