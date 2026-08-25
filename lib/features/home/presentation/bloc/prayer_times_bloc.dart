import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';

import 'prayer_times_event.dart';
import 'prayer_times_state.dart';

export 'prayer_times_event.dart';
export 'prayer_times_state.dart';

class _ClockTicked extends PrayerTimesEvent {
  const _ClockTicked();
}

class PrayerTimesBloc extends Bloc<PrayerTimesEvent, PrayerTimesState> {
  PrayerTimesBloc({this.prayerTimeService, DateTime Function()? now})
    : _now = now ?? bangladeshNow,
      super(PrayerTimesState(now: (now ?? bangladeshNow)())) {
    on<LoadPrayerTimes>((event, emit) => _loadTimes(_now(), emit));
    on<StartClock>((event, emit) => _scheduleNextTick());
    on<_ClockTicked>((event, emit) async {
      final current = _now();
      if (state.times?.dateKey != _dateKey(current)) {
        await _loadTimes(current, emit);
      }
      emit(state.copyWith(now: current));
      _scheduleNextTick();
    });
  }

  final PrayerTimeService? prayerTimeService;
  final DateTime Function() _now;
  Timer? _clockTimer;

  Future<void> _loadTimes(DateTime now, Emitter<PrayerTimesState> emit) async {
    try {
      final service =
          prayerTimeService ?? await AladhanPrayerTimeService.create();
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

  void _scheduleNextTick() {
    _clockTimer?.cancel();
    final now = _now();
    final nextMinute = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    _clockTimer = Timer(
      nextMinute.difference(now),
      () => add(const _ClockTicked()),
    );
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
