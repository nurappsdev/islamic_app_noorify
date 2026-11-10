import 'package:tuhfatul_muslim/features/alarm/domain/entities/alarm_entry.dart';

abstract class AlarmListEvent {
  const AlarmListEvent();
}

/// Fetches the saved alarms. Fired once when the bloc is created.
class LoadAlarms extends AlarmListEvent {
  const LoadAlarms();
}

/// Persists [alarm] and appends it to the list once saved.
class SaveAlarm extends AlarmListEvent {
  const SaveAlarm(this.alarm);

  final AlarmEntry alarm;
}

/// Flips the enabled state of the alarm identified by [id].
class ToggleAlarmEnabled extends AlarmListEvent {
  const ToggleAlarmEnabled(this.id, this.enabled);

  final String id;
  final bool enabled;
}

/// Flips one prayer alarm — [prayerType] is `fajr`, `dhuhr`, `asr`,
/// `maghrib`, `isha` or `tahajjud` — on or off, leaving the other prayers and
/// this one's saved settings alone.
class TogglePrayerAlarmEnabled extends AlarmListEvent {
  const TogglePrayerAlarmEnabled(this.prayerType, this.enabled);

  final String prayerType;
  final bool enabled;
}

/// Deletes the alarm identified by [id].
class RemoveAlarm extends AlarmListEvent {
  const RemoveAlarm(this.id);

  final String id;
}
