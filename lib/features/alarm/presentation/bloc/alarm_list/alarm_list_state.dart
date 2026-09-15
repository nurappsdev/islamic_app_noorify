import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';

enum AlarmListStatus { initial, loading, success, failure }

class AlarmListState {
  const AlarmListState({
    this.status = AlarmListStatus.initial,
    this.alarms = const [],
    this.failure,
  });

  final AlarmListStatus status;
  final List<AlarmEntry> alarms;
  final Failure? failure;

  bool get isLoading => status == AlarmListStatus.loading;

  AlarmListState copyWith({
    AlarmListStatus? status,
    List<AlarmEntry>? alarms,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return AlarmListState(
      status: status ?? this.status,
      alarms: alarms ?? this.alarms,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
