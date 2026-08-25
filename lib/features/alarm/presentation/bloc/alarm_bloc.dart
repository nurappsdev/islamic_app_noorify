import 'package:bloc/bloc.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

import 'alarm_event.dart';
import 'alarm_state.dart';

export 'alarm_event.dart';
export 'alarm_state.dart';

class AlarmBloc extends Bloc<AlarmEvent, AlarmState> {
  AlarmBloc({PrayerClockTime? initialTime})
    : super(
        initialTime == null
            ? const AlarmState()
            : AlarmState.fromTime(initialTime),
      ) {
    on<SelectHour>(
      (event, emit) => emit(state.copyWith(hourIndex: event.index)),
    );
    on<SelectMinute>(
      (event, emit) => emit(state.copyWith(minuteIndex: event.index)),
    );
    on<SelectPeriod>(
      (event, emit) => emit(state.copyWith(periodIndex: event.index)),
    );
    on<SelectOffset>(
      (event, emit) => emit(state.copyWith(offsetIndex: event.index)),
    );
    on<SetVibrateAndRing>(
      (event, emit) => emit(state.copyWith(vibrateAndRing: event.value)),
    );
    on<SetVibrate>((event, emit) => emit(state.copyWith(vibrate: event.value)));
    on<SetRing>((event, emit) => emit(state.copyWith(ring: event.value)));
  }
}
