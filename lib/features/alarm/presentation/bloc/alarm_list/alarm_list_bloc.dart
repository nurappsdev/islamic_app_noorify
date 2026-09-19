import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/alarm/data/services/alarm_scheduler.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/add_alarm.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/delete_alarm.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_alarm_dashboard.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_alarms.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_ringtones.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/set_alarm_enabled.dart';

import 'alarm_list_event.dart';
import 'alarm_list_state.dart';

export 'alarm_list_event.dart';
export 'alarm_list_state.dart';

class AlarmListBloc extends Bloc<AlarmListEvent, AlarmListState> {
  AlarmListBloc({
    required GetAlarms getAlarms,
    required GetAlarmDashboard getAlarmDashboard,
    required AddAlarm addAlarm,
    required SetAlarmEnabled setAlarmEnabled,
    required DeleteAlarm deleteAlarm,
    GetRingtones? getRingtones,
  }) : _getRingtones = getRingtones,
       _getAlarms = getAlarms,
       _getAlarmDashboard = getAlarmDashboard,
       _addAlarm = addAlarm,
       _setAlarmEnabled = setAlarmEnabled,
       _deleteAlarm = deleteAlarm,
       super(const AlarmListState()) {
    on<LoadAlarms>(_onLoadAlarms);
    on<SaveAlarm>(_onSaveAlarm);
    on<ToggleAlarmEnabled>(_onToggleAlarmEnabled);
    on<RemoveAlarm>(_onRemoveAlarm);
  }

  final GetAlarms _getAlarms;
  final GetAlarmDashboard _getAlarmDashboard;
  final AddAlarm _addAlarm;
  final SetAlarmEnabled _setAlarmEnabled;
  final DeleteAlarm _deleteAlarm;
  final GetRingtones? _getRingtones;

  /// Loads the `GET /alarms` dashboard, which backs the header countdown,
  /// the "Prayers Alarm" tab, and — via its `customAlarms` — the "All Alarm"
  /// tab too: the server is the source of truth there, since every save
  /// already goes through `POST /alarms/custom` first (see [_onSaveAlarm]).
  /// The local Hive cache is only consulted as a fallback when the
  /// dashboard call itself fails (e.g. offline), so the screen still shows
  /// whatever was last saved on this device.
  Future<void> _onLoadAlarms(
    LoadAlarms event,
    Emitter<AlarmListState> emit,
  ) async {
    emit(state.copyWith(status: AlarmListStatus.loading));
    final dashboardResult = await _getAlarmDashboard();
    final prayerAlarms = dashboardResult.fold(
      (_) => state.prayerAlarms,
      (dashboard) => dashboard.prayerAlarms,
    );
    // Arms this device's OS alarms for the prayer alarms too, so they
    // actually ring at their time (they have no local copy otherwise).
    dashboardResult.fold(
      (_) {},
      (dashboard) => unawaited(_schedulePrayerAlarms(dashboard.prayerAlarms)),
    );
    final serverCountdown = dashboardResult.fold(
      (_) => state.serverCountdown,
      (dashboard) => dashboard.nextAlarmCountdown,
    );
    final serverAlarms = dashboardResult.fold(
      (_) => null,
      (dashboard) => dashboard.customAlarms,
    );
    final result = serverAlarms != null
        ? Right<Failure, List<AlarmEntry>>(serverAlarms)
        : await _getAlarms();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AlarmListStatus.failure,
          failure: failure,
          prayerAlarms: prayerAlarms,
          serverCountdown: serverCountdown,
        ),
      ),
      (alarms) {
        // Keeps this device's OS-level schedule in sync with whatever the
        // server says is saved — including alarms created elsewhere (another
        // device, a direct API call) that this device has never scheduled.
        if (serverAlarms != null) {
          unawaited(_cancelStaleLocalAlarms({for (final a in alarms) a.id}));
        }
        unawaited(AlarmScheduler.rescheduleAll(alarms));
        emit(
          state.copyWith(
            status: AlarmListStatus.success,
            alarms: alarms,
            prayerAlarms: prayerAlarms,
            serverCountdown: serverCountdown,
            clearFailure: true,
          ),
        );
      },
    );
  }

  /// The on-device cache keys alarms by an id made up at save time, while
  /// the server hands back its own — so the same alarm would otherwise be
  /// armed twice (once per id) and ring twice. The server's ids win; any
  /// cached id it doesn't know about is disarmed.
  Future<void> _cancelStaleLocalAlarms(Set<String> serverIds) async {
    final local = await _getAlarms();
    for (final alarm in local.getOrElse(() => const [])) {
      if (!serverIds.contains(alarm.id)) {
        await AlarmScheduler.cancelAlarm(alarm.id);
      }
    }
  }

  Future<void> _schedulePrayerAlarms(List<PrayerAlarm> prayers) async {
    try {
      final catalog = await _getRingtones?.call();
      final ringtoneUrls = <String, String>{
        ...?catalog?.fold(
          (_) => null,
          (list) => {for (final r in list) r.id: r.audioUrl},
        ),
      };
      await AlarmScheduler.reschedulePrayerAlarms(
        prayers,
        ringtoneUrls: ringtoneUrls,
      );
    } catch (_) {
      // Best-effort: the next successful load re-arms them.
    }
  }

  Future<void> _onSaveAlarm(
    SaveAlarm event,
    Emitter<AlarmListState> emit,
  ) async {
    final result = await _addAlarm(event.alarm);
    result.fold((failure) => emit(state.copyWith(failure: failure)), (saved) {
      emit(
        state.copyWith(alarms: [...state.alarms, saved], clearFailure: true),
      );
      // Not armed here: `saved` carries a client-made id, and arming it as
      // well as the server's own id would make one alarm ring twice.
      // Reloading arms it once, under the server id.
      add(const LoadAlarms());
    });
  }

  /// Flips the toggle immediately (optimistic), then persists it — reverting
  /// if the write fails so the switch never shows a state that wasn't saved.
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
        final alarm = updated.firstWhere((a) => a.id == event.id);
        unawaited(
          event.enabled
              ? AlarmScheduler.scheduleAlarm(alarm)
              : AlarmScheduler.cancelAlarm(event.id),
        );
      },
    );
  }

  /// Removes the alarm immediately (optimistic), then persists the delete —
  /// restoring it if the write fails so the list never drops an alarm that
  /// wasn't actually deleted server-side.
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
      (_) => unawaited(AlarmScheduler.cancelAlarm(event.id)),
    );
  }
}
