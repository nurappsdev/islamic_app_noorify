import 'dart:convert';

import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';

/// Everything an "alarm is ringing" screen needs to know, carried through a
/// notification's `payload` string (or an `AndroidAlarmManager` `params`
/// map) between the moment an alarm fires — in a background isolate, with no
/// access to the running app's state — and the UI that actually rings it.
class AlarmRingPayload {
  const AlarmRingPayload({
    required this.alarmId,
    required this.hour,
    required this.minute,
    required this.label,
    required this.vibrate,
    required this.vibrateAndRing,
    required this.ring,
    required this.ringtoneId,
    required this.ringtoneName,
    required this.ringtoneUrl,
  });

  final String alarmId;

  /// 24-hour clock, 0-23.
  final int hour;

  /// 0-59.
  final int minute;

  final String label;
  final bool vibrate;
  final bool vibrateAndRing;
  final bool ring;
  final String ringtoneId;
  final String ringtoneName;
  final String ringtoneUrl;

  bool get shouldPlaySound => ring || vibrateAndRing;
  bool get shouldVibrate => vibrate || vibrateAndRing;

  factory AlarmRingPayload.fromEntity(AlarmEntry alarm) => AlarmRingPayload(
    alarmId: alarm.id,
    hour: alarm.hour,
    minute: alarm.minute,
    label: alarm.label,
    vibrate: alarm.vibrate,
    vibrateAndRing: alarm.vibrateAndRing,
    ring: alarm.ring,
    ringtoneId: alarm.ringtoneId,
    ringtoneName: alarm.ringtoneName,
    ringtoneUrl: alarm.ringtoneUrl,
  );

  factory AlarmRingPayload.fromJson(Map<String, dynamic> json) =>
      AlarmRingPayload(
        alarmId: json['alarmId'] as String,
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        label: json['label'] as String? ?? '',
        vibrate: json['vibrate'] as bool? ?? false,
        vibrateAndRing: json['vibrateAndRing'] as bool? ?? false,
        ring: json['ring'] as bool? ?? false,
        ringtoneId:
            json['ringtoneId'] as String? ?? AlarmEntry.defaultRingtoneId,
        ringtoneName:
            json['ringtoneName'] as String? ?? AlarmEntry.defaultRingtoneName,
        ringtoneUrl: json['ringtoneUrl'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'alarmId': alarmId,
    'hour': hour,
    'minute': minute,
    'label': label,
    'vibrate': vibrate,
    'vibrateAndRing': vibrateAndRing,
    'ring': ring,
    'ringtoneId': ringtoneId,
    'ringtoneName': ringtoneName,
    'ringtoneUrl': ringtoneUrl,
  };

  String encode() => jsonEncode(toJson());

  /// Decodes a notification `payload` string, or `null` if it's missing or
  /// malformed (e.g. a notification left over from a previous app version).
  static AlarmRingPayload? tryDecode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      return AlarmRingPayload.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }
}
