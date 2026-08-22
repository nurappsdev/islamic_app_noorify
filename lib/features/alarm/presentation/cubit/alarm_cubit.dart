import 'package:bloc/bloc.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

import 'alarm_state.dart';

export 'alarm_state.dart';

class AlarmCubit extends Cubit<AlarmState> {
  AlarmCubit({PrayerClockTime? initialTime})
    : super(
        initialTime == null
            ? const AlarmState()
            : AlarmState.fromTime(initialTime),
      );

  void selectHour(int index) => emit(state.copyWith(hourIndex: index));
  void selectMinute(int index) => emit(state.copyWith(minuteIndex: index));
  void selectPeriod(int index) => emit(state.copyWith(periodIndex: index));
  void selectOffset(String offset) => emit(state.copyWith(offset: offset));
  void setVibrateAndRing(bool value) =>
      emit(state.copyWith(vibrateAndRing: value));
  void setVibrate(bool value) => emit(state.copyWith(vibrate: value));
  void setRing(bool value) => emit(state.copyWith(ring: value));
}
