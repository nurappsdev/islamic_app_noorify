import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/alarm/domain/usecases/add_alarm.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_alarms.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/set_alarm_enabled.dart';

import 'alarm_list_event.dart';
import 'alarm_list_state.dart';

export 'alarm_list_event.dart';
export 'alarm_list_state.dart';

class AlarmListBloc extends Bloc<AlarmListEvent, AlarmListState> {
  AlarmListBloc({
    required GetAlarms getAlarms,
    required AddAlarm addAlarm,
    required SetAlarmEnabled setAlarmEnabled,
  }) : _getAlarms = getAlarms,
       _addAlarm = addAlarm,
       _setAlarmEnabled = setAlarmEnabled,
       super(const AlarmListState()) {
    on<LoadAlarms>(_onLoadAlarms);
    on<SaveAlarm>(_onSaveAlarm);
    on<ToggleAlarmEnabled>(_onToggleAlarmEnabled);
  }

  final GetAlarms _getAlarms;
  final AddAlarm _addAlarm;
  final SetAlarmEnabled _setAlarmEnabled;

  Future<void> _onLoadAlarms(
    LoadAlarms event,
    Emitter<AlarmListState> emit,
  ) async {
    emit(state.copyWith(status: AlarmListStatus.loading));
    final result = await _getAlarms();
    result.fold(
      (failure) => emit(
        state.copyWith(status: AlarmListStatus.failure, failure: failure),
      ),
      (alarms) => emit(
        state.copyWith(
          status: AlarmListStatus.success,
          alarms: alarms,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<void> _onSaveAlarm(
    SaveAlarm event,
    Emitter<AlarmListState> emit,
  ) async {
    final result = await _addAlarm(event.alarm);
    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (saved) => emit(
        state.copyWith(alarms: [...state.alarms, saved], clearFailure: true),
      ),
    );
  }

  /// Flips the toggle immediately (optimistic), then persists it — reverting
  /// if the write fails so the switch never shows a state that wasn't saved.
  Future<void> _onToggleAlarmEnabled(
    ToggleAlarmEnabled event,
    Emitter<AlarmListState> emit,
  ) async {
    final previous = state.alarms;
    emit(
      state.copyWith(
        alarms: [
          for (final alarm in previous)
            if (alarm.id == event.id)
              alarm.copyWith(enabled: event.enabled)
            else
              alarm,
        ],
      ),
    );
    final result = await _setAlarmEnabled(id: event.id, enabled: event.enabled);
    result.fold(
      (failure) => emit(state.copyWith(alarms: previous, failure: failure)),
      (_) {},
    );
  }
}
