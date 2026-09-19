import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';

/// One entry of `GET /alarms`'s `customAlarms` array — the server's view of
/// a saved custom alarm. Its JSON shape differs from what `AlarmModel`/Hive
/// use locally: `time` is a 12-hour string instead of `hour`/`minute` ints,
/// `soundMode` is a single string instead of 3 booleans, `isEnabled` instead
/// of `enabled`, and it carries a resolved `audioUrl` for the ringtone.
class CustomAlarmModel extends AlarmEntry {
  const CustomAlarmModel({
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

  factory CustomAlarmModel.fromJson(Map<String, dynamic> json) {
    final parsed = parseClockTime12h(json['time'] as String? ?? '');
    final soundMode = json['soundMode'] as String? ?? 'vibrate_and_ring';
    return CustomAlarmModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      hour: parsed?.hour ?? 0,
      minute: parsed?.minute ?? 0,
      vibrateAndRing: soundMode == 'vibrate_and_ring',
      vibrate: soundMode == 'vibrate',
      ring: soundMode == 'ring',
      enabled: json['isEnabled'] as bool? ?? true,
      label: json['label'] as String? ?? '',
      ringtoneId: json['ringtoneId'] as String? ?? AlarmEntry.defaultRingtoneId,
      ringtoneName:
          json['ringtoneName'] as String? ?? AlarmEntry.defaultRingtoneName,
      ringtoneUrl: json['audioUrl'] as String? ?? '',
    );
  }
}
