import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/alarm/data/services/alarm_scheduler.dart';
import 'package:islami_app_noorify/features/alarm/data/services/alarm_sync.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/add_alarm.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/delete_alarm.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_alarms.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_prayer_alarms.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/set_alarm_enabled.dart';

import 'alarm_list_event.dart';
import 'alarm_list_state.dart';

export 'alarm_list_event.dart';
export 'alarm_list_state.dart';

/// The alarm screens' state. Every alarm lives on the device: each change is
/// saved locally first, then the OS alarm schedule is brought in line with it
/// (see [syncLocalAlarms]). Nothing here talks to the server.
class AlarmListBloc extends Bloc<AlarmListEvent, AlarmListState> {
  AlarmListBloc({
    required GetAlarms getAlarms,
    required GetPrayerAlarms getPrayerAlarms,
    required AddAlarm addAlarm,
    required SetAlarmEnabled setAlarmEnabled,
    required DeleteAlarm deleteAlarm,
    Future<void> Function()? syncAlarms,
    Future<void> Function(String id, String reason)? cancelAlarm,
  }) : _getAlarms = getAlarms,
       _getPrayerAlarms = getPrayerAlarms,
       _addAlarm = addAlarm,
       _setAlarmEnabled = setAlarmEnabled,
       _deleteAlarm = deleteAlarm,
       _syncAlarms = syncAlarms ?? syncLocalAlarms,
       _cancelAlarm =
           cancelAlarm ??
           ((id, reason) => AlarmScheduler.cancelAlarm(id, reason: reason)),
       super(const AlarmListState()) {
    on<LoadAlarms>(_onLoadAlarms);
    on<SaveAlarm>(_onSaveAlarm);
    on<ToggleAlarmEnabled>(_onToggleAlarmEnabled);
    on<RemoveAlarm>(_onRemoveAlarm);
  }

  final GetAlarms _getAlarms;
  final GetPrayerAlarms _getPrayerAlarms;
  final AddAlarm _addAlarm;
  final SetAlarmEnabled _setAlarmEnabled;
  final DeleteAlarm _deleteAlarm;
  final Future<void> Function() _syncAlarms;
  final Future<void> Function(String id, String reason) _cancelAlarm;

  /// Loads the saved custom alarms and the prayer alarms from the device.
  Future<void> _onLoadAlarms(
    LoadAlarms event,
    Emitter<AlarmListState> emit,
  ) async {
    emit(state.copyWith(status: AlarmListStatus.loading));
    final alarms = await _getAlarms();
    final prayerAlarms = await _getPrayerAlarms();
    alarms.fold(
      (failure) => emit(
        state.copyWith(status: AlarmListStatus.failure, failure: failure),
      ),
      (list) => emit(
        state.copyWith(
          status: AlarmListStatus.success,
          alarms: list,
          prayerAlarms: prayerAlarms.getOrElse(() => state.prayerAlarms),
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
    await result.fold(
      (failure) async => emit(state.copyWith(failure: failure)),
      (saved) async {
        emit(
          state.copyWith(alarms: [...state.alarms, saved], clearFailure: true),
        );
        unawaited(_syncAlarms());
      },
    );
  }

  /// Flips the toggle immediately (optimistic), then saves it - reverting if
  /// the save fails so the switch never shows a state that wasn't saved.
  Future<void> _onToggleAlarmEnabled(
    ToggleAlarmEnabled event,
    Emitter<AlarmListState> emit,
  ) async {
    final previous = state.alarms;
    final updated = [
      for (final alarm in previous)
        if (alarm.id == event.id)
          alarm.copyWith(enabled: event.enabled)
        else
          alarm,
    ];
    emit(state.copyWith(alarms: updated));
    final result = await _setAlarmEnabled(id: event.id, enabled: event.enabled);
    result.fold(
      (failure) => emit(state.copyWith(alarms: previous, failure: failure)),
      (_) {
        if (!event.enabled) unawaited(_cancelAlarm(event.id, 'switched off'));
        unawaited(_syncAlarms());
      },
    );
  }

  /// Removes the alarm immediately (optimistic), then deletes it - restoring
  /// it if that fails so the list never drops an alarm that wasn't deleted.
  Future<void> _onRemoveAlarm(
    RemoveAlarm event,
    Emitter<AlarmListState> emit,
  ) async {
    final previous = state.alarms;
    final index = previous.indexWhere((a) => a.id == event.id);
    if (index == -1) return;
    emit(state.copyWith(alarms: [...previous]..removeAt(index)));
    final result = await _deleteAlarm(event.id);
    result.fold(
      (failure) => emit(state.copyWith(alarms: previous, failure: failure)),
      (_) {
        // Cancel right away; the sync then double-checks nothing of it is left.
        unawaited(_cancelAlarm(event.id, 'deleted by the user'));
        unawaited(_syncAlarms());
      },
    );
  }
}
