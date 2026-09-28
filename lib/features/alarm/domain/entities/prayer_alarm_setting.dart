/// What the user saved for one prayer's alarm, stored on the device.
///
/// It holds no time: a prayer alarm rings [offsetMinutesBefore] minutes before
/// the prayer starts, and the start moves every day.
class PrayerAlarmSetting {
  const PrayerAlarmSetting({
    required this.prayerType,
    this.enabled = false,
    this.offsetMinutesBefore = 0,
    this.soundMode = defaultSoundMode,
    this.ringtoneId = defaultRingtoneId,
    this.ringtoneName = defaultRingtoneName,
    this.ringtoneUrl = '',
  });

  static const defaultSoundMode = 'vibrate_and_ring';
  static const defaultRingtoneId = 'makkah_adhan';
  static const defaultRingtoneName = 'Makkah Al-Mukarramah Adhan';

  final String prayerType;
  final bool enabled;
  final int offsetMinutesBefore;

  /// `ring`, `vibrate` or `vibrate_and_ring`.
  final String soundMode;
  final String ringtoneId;
  final String ringtoneName;
  final String ringtoneUrl;

  PrayerAlarmSetting copyWith({
    bool? enabled,
    int? offsetMinutesBefore,
    String? soundMode,
    String? ringtoneId,
    String? ringtoneName,
    String? ringtoneUrl,
  }) {
    return PrayerAlarmSetting(
      prayerType: prayerType,
      enabled: enabled ?? this.enabled,
      offsetMinutesBefore: offsetMinutesBefore ?? this.offsetMinutesBefore,
      soundMode: soundMode ?? this.soundMode,
      ringtoneId: ringtoneId ?? this.ringtoneId,
      ringtoneName: ringtoneName ?? this.ringtoneName,
      ringtoneUrl: ringtoneUrl ?? this.ringtoneUrl,
    );
  }
}
