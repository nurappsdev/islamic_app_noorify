import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/amol_tracking/domain/usecases/get_amol_analytics_graph.dart';

import 'amol_dashboard_event.dart';
import 'amol_dashboard_state.dart';

export 'amol_dashboard_event.dart';
export 'amol_dashboard_state.dart';

/// `_timeframeByPeriod`'s index lines up with `_AmolPeriod.values`
/// (daily/weekly/monthly) in `amol_dashboard_screen.dart`.
const _timeframeByPeriod = ['daily', 'weekly', 'monthly'];

class AmolDashboardBloc extends Bloc<AmolDashboardEvent, AmolDashboardState> {
  AmolDashboardBloc(this._getGraph, {DateTime Function()? now})
    : super(
        AmolDashboardState(
          selectedPeriod: 0,
          date: (now ?? DateTime.now)(),
          today: (now ?? DateTime.now)(),
        ),
      ) {
    on<SelectPeriod>(_onSelectPeriod);
    on<ShiftDate>(_onShiftDate);
    on<SelectMonth>(_onSelectMonth);
    on<LoadGraph>((event, emit) => _load(emit));
  }

  final GetAmolAnalyticsGraph _getGraph;

  /// Guards against a slow, now-stale request (e.g. the "daily" fetch)
  /// resolving *after* a newer one (e.g. "weekly", tapped right after) and
  /// overwriting it — `on<Event>` runs same-type events concurrently by
  /// default, so without this a fast tab switch could otherwise leave the
  /// points/progress/chart showing a different period's data than the
  /// selected tab.
  int _requestId = 0;

  Future<void> _onSelectPeriod(
    SelectPeriod event,
    Emitter<AmolDashboardState> emit,
  ) async {
    if (state.selectedPeriod == event.period) return;
    emit(state.copyWith(selectedPeriod: event.period));
    await _load(emit);
  }

  Future<void> _onShiftDate(
    ShiftDate event,
    Emitter<AmolDashboardState> emit,
  ) async {
    emit(state.copyWith(date: state.date.add(event.step * event.direction)));
    await _load(emit);
  }

  /// Jumps straight to one calendar month, e.g. picked from the monthly
  /// tab's "last 12 months" dropdown: the current month anchors on
  /// [AmolDashboardState.today] (matching the default today-based window);
  /// any other month anchors on its last day, so the same
  /// `date=...&timeframe=monthly` request the server already understands
  /// covers that month.
  Future<void> _onSelectMonth(
    SelectMonth event,
    Emitter<AmolDashboardState> emit,
  ) async {
    final isCurrentMonth =
        event.month.year == state.today.year &&
        event.month.month == state.today.month;
    final target = isCurrentMonth ? state.today : _lastDayOfMonth(event.month);
    emit(state.copyWith(date: target));
    await _load(emit);
  }

  /// Hits `GET /amol/analytics/graph?date=[isoDate]&timeframe=[timeframe]`
  /// for the state's current date/period, e.g. daily on 2026-09-15 ->
  /// `date=2026-09-15&timeframe=daily`; shifting a week back on the weekly
  /// tab -> `date=2026-09-08&timeframe=weekly`.
  Future<void> _load(Emitter<AmolDashboardState> emit) async {
    final requestId = ++_requestId;
    emit(state.copyWith(status: AmolDashboardStatus.loading));
    final result = await _getGraph(
      date: _isoDate(state.date),
      timeframe: _timeframeByPeriod[state.selectedPeriod],
    );
    // A newer request already started (another tab/date/month tapped while
    // this one was in flight) — drop this now-stale response instead of
    // letting it clobber the newer state.
    if (requestId != _requestId) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: AmolDashboardStatus.failure, failure: failure),
      ),
      (graph) => emit(
        state.copyWith(
          status: AmolDashboardStatus.success,
          graph: graph,
          clearFailure: true,
        ),
      ),
    );
  }

  static String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime _lastDayOfMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0);
}
