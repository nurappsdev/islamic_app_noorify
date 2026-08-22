import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';

import 'prayer_times_state.dart';

export 'prayer_times_state.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit({this.prayerTimeService, DateTime Function()? now})
    : _now = now ?? bangladeshNow,
      super(PrayerTimesState(now: (now ?? bangladeshNow)()));

  final PrayerTimeService? prayerTimeService;
  final DateTime Function() _now;
  Timer? _clockTimer;

  Future<void> loadPrayerTimes() async {
    try {
      final service =
          prayerTimeService ?? await AladhanPrayerTimeService.create();
      final now = _now();
      final cached = service.cachedPrayerTimes(now);
      if (cached != null) emit(state.copyWith(now: now, times: cached));

      final fresh = await service.loadPrayerTimes(now);
      if (fresh != null) emit(state.copyWith(now: now, times: fresh));
    } catch (_) {
      emit(state.copyWith(now: _now(), isLoading: false));
      return;
    }

    emit(state.copyWith(now: _now(), isLoading: false));
  }

  void startClock() {
    _clockTimer?.cancel();
    final now = _now();
    final nextMinute = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    _clockTimer = Timer(nextMinute.difference(now), () async {
      final current = _now();
      if (state.times?.dateKey != _dateKey(current)) await loadPrayerTimes();
      emit(state.copyWith(now: current));
      startClock();
    });
  }

  @override
  Future<void> close() {
    _clockTimer?.cancel();
    return super.close();
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
