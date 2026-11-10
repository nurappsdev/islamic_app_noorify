import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/alarm_entry.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/prayer_alarm.dart';

enum AlarmListStatus { initial, loading, success, failure }

class AlarmListState {
  const AlarmListState({
    this.status = AlarmListStatus.initial,
    this.alarms = const [],
    this.prayerAlarms = const [],
    this.failure,
  });

  final AlarmListStatus status;
  final List<AlarmEntry> alarms;

  /// The six prayer alarms - the "Prayers Alarm" tab - whether on or off.
  final List<PrayerAlarm> prayerAlarms;

  final Failure? failure;

  bool get isLoading => status == AlarmListStatus.loading;

  AlarmListState copyWith({
    AlarmListStatus? status,
    List<AlarmEntry>? alarms,
    List<PrayerAlarm>? prayerAlarms,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return AlarmListState(
      status: status ?? this.status,
      alarms: alarms ?? this.alarms,
      prayerAlarms: prayerAlarms ?? this.prayerAlarms,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
