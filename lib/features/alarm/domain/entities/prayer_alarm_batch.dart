/// The "Set All Alarm" settings applied to several prayers at once
/// (`POST /alarms/prayers/batch`).
class PrayerAlarmBatch {
  const PrayerAlarmBatch({
    required this.offsetMinutesBefore,
    required this.soundMode,
    required this.ringtoneId,
    required this.selectedPrayers,
  });

  /// Minutes before each prayer the alarm fires (20/30/40 or custom).
  final int offsetMinutesBefore;

  /// One of `ring`, `vibrate`, `vibrate_and_ring`.
  final String soundMode;

  final String ringtoneId;

  /// Prayer keys as the API spells them: `fajr`, `dhuhr`, `asr`, `maghrib`,
  /// `isha` (and `tahajjud`).
  final List<String> selectedPrayers;
}
