import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_home_cubit.dart'
    show DuaLoadStatus;

/// The three windows `GET /duas/reading/dashboard` answers for; [name] is
/// sent verbatim as the `timeframe` query parameter.
enum DuaDashboardTimeframe { daily, weekly, monthly }

class DuaReadingDashboardState {
  const DuaReadingDashboardState({
    this.timeframe = DuaDashboardTimeframe.daily,
    this.status = DuaLoadStatus.initial,
    this.cache = const {},
    this.error,
    this.refreshing = false,
  });

  final DuaDashboardTimeframe timeframe;
  final DuaLoadStatus status;

  /// One answer per timeframe, kept so switching back to a window already
  /// loaded shows it with no spinner and no wait.
  final Map<DuaDashboardTimeframe, DuaReadingDashboard> cache;
  final String? error;

  /// A silent re-fetch behind an already-shown window.
  final bool refreshing;

  DuaReadingDashboard? get dashboard => cache[timeframe];

  DuaReadingDashboardState copyWith({
    DuaDashboardTimeframe? timeframe,
    DuaLoadStatus? status,
    Map<DuaDashboardTimeframe, DuaReadingDashboard>? cache,
    String? error,
    bool? refreshing,
  }) => DuaReadingDashboardState(
    timeframe: timeframe ?? this.timeframe,
    status: status ?? this.status,
    cache: cache ?? this.cache,
    error: error,
    refreshing: refreshing ?? this.refreshing,
  );
}

/// Loads `GET /duas/reading/dashboard` for the Dua reading dashboard.
///
/// Every timeframe's answer is cached: `Daily -> Weekly -> Daily` shows the
/// kept daily answer at once and refreshes it behind the already-visible
/// chart, so the second visit never falls back to a skeleton.
class DuaReadingDashboardCubit extends Cubit<DuaReadingDashboardState> {
  DuaReadingDashboardCubit(this._repository)
    : super(const DuaReadingDashboardState());

  final DuaRepository _repository;

  /// Switches the window. A cached one is shown immediately and revalidated
  /// in the background; an unseen one loads with the skeleton.
  Future<void> select(DuaDashboardTimeframe timeframe) async {
    if (state.timeframe == timeframe) return;
    final cached = state.cache[timeframe];
    emit(
      state.copyWith(
        timeframe: timeframe,
        status: cached == null ? DuaLoadStatus.loading : DuaLoadStatus.success,
      ),
    );
    await _fetch(timeframe, silent: cached != null);
  }

  /// First load, pull-to-refresh and retry.
  Future<void> load({bool silent = false}) =>
      _fetch(state.timeframe, silent: silent || state.dashboard != null);

  Future<void> _fetch(
    DuaDashboardTimeframe timeframe, {
    required bool silent,
  }) async {
    if (isClosed) return;
    emit(
      silent
          ? state.copyWith(refreshing: true)
          : state.copyWith(status: DuaLoadStatus.loading),
    );
    try {
      final dashboard = await _repository.getReadingDashboard(
        timeframe: timeframe.name,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          cache: {...state.cache, timeframe: dashboard},
          // A window switched away from while this was in flight keeps its
          // own status; only the stored answer is updated.
          status: state.timeframe == timeframe
              ? DuaLoadStatus.success
              : state.status,
          refreshing: false,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          // A silent refresh that fails leaves what is on screen alone.
          status: silent ? state.status : DuaLoadStatus.failure,
          error: silent ? null : '$error',
          refreshing: false,
        ),
      );
    }
  }
}
