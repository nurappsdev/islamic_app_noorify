/// The "Set All Alarm" settings applied to several prayers at once: the
/// selected prayers get an alarm with these settings, the others are turned
/// off.
class PrayerAlarmBatch {
  const PrayerAlarmBatch({
    required this.offsetMinutesBefore,
    required this.soundMode,
    required this.ringtoneId,
    required this.selectedPrayers,
    this.ringtoneName = '',
    this.ringtoneUrl = '',
  });

  /// Minutes before each prayer the alarm fires (20/30/40 or custom).
  final int offsetMinutesBefore;

  /// One of `ring`, `vibrate`, `vibrate_and_ring`.
  final String soundMode;

  /// The ringtone picked from the catalog; [ringtoneName] and [ringtoneUrl]
  /// are kept with it so the alarm can play without the catalog.
  final String ringtoneId;
  final String ringtoneName;
  final String ringtoneUrl;

  /// Prayer keys: `fajr`, `dhuhr`, `asr`, `maghrib`, `isha` (and `tahajjud`).
  final List<String> selectedPrayers;
}
