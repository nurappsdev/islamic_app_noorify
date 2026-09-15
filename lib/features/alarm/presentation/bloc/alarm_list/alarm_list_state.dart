import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm.dart';

enum AlarmListStatus { initial, loading, success, failure }

class AlarmListState {
  const AlarmListState({
    this.status = AlarmListStatus.initial,
    this.alarms = const [],
    this.prayerAlarms = const [],
    this.serverCountdown,
    this.failure,
  });

  final AlarmListStatus status;
  final List<AlarmEntry> alarms;

  /// From `GET /alarms`'s `prayerAlarms` — the "Prayers Alarm" tab.
  final List<PrayerAlarm> prayerAlarms;

  /// The server's pre-formatted "Alarm will be ring in X hr Y min", which
  /// accounts for prayer alarms too — preferred over any client-side
  /// countdown computed from [alarms] alone. `null` until the dashboard
  /// fetch succeeds at least once.
  final String? serverCountdown;

  final Failure? failure;

  bool get isLoading => status == AlarmListStatus.loading;

  AlarmListState copyWith({
    AlarmListStatus? status,
    List<AlarmEntry>? alarms,
    List<PrayerAlarm>? prayerAlarms,
    String? serverCountdown,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return AlarmListState(
      status: status ?? this.status,
      alarms: alarms ?? this.alarms,
      prayerAlarms: prayerAlarms ?? this.prayerAlarms,
      serverCountdown: serverCountdown ?? this.serverCountdown,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
