/// A single saved alarm, shown on the "All Alarm" list.
class AlarmEntry {
  const AlarmEntry({
    required this.id,
    required this.hour,
    required this.minute,
    required this.vibrateAndRing,
    required this.vibrate,
    required this.ring,
    required this.enabled,
    this.label = '',
    this.ringtoneId = defaultRingtoneId,
    this.ringtoneName = defaultRingtoneName,
    this.ringtoneUrl = '',
  });

  /// Used until the user picks one from the `GET /alarms/ringtones` catalog.
  static const defaultRingtoneId = 'makkah_adhan';
  static const defaultRingtoneName = 'Makkah Al-Mukarramah Adhan';

  final String id;

  /// 24-hour clock, 0-23.
  final int hour;

  /// 0-59.
  final int minute;

  final bool vibrateAndRing;
  final bool vibrate;
  final bool ring;
  final bool enabled;
  final String label;
  final String ringtoneId;
  final String ringtoneName;

  /// The ringtone's playable audio URL (from the `GET /alarms/ringtones`
  /// catalog) — kept only on-device (never sent to the server) so the alarm
  /// can actually play the chosen sound when it fires. Empty when the user
  /// never picked a ringtone.
  final String ringtoneUrl;

  AlarmEntry copyWith({bool? enabled}) {
    return AlarmEntry(
      id: id,
      hour: hour,
      minute: minute,
      vibrateAndRing: vibrateAndRing,
      vibrate: vibrate,
      ring: ring,
      enabled: enabled ?? this.enabled,
      label: label,
      ringtoneId: ringtoneId,
      ringtoneName: ringtoneName,
      ringtoneUrl: ringtoneUrl,
    );
  }
}
