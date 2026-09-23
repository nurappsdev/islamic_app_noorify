import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/amol_tracking/domain/usecases/get_amol_analytics_graph.dart';

import 'amol_dashboard_event.dart';
import 'amol_dashboard_state.dart';

export 'amol_dashboard_event.dart';
export 'amol_dashboard_state.dart';

/// Index-aligned with `_AmolPeriod.values` (daily/weekly/monthly) in
/// `amol_dashboard_screen.dart`.
const _timeframeByPeriod = ['daily', 'weekly', 'monthly'];

/// Sliding-window length per period, confirmed against the real API: daily
/// is a single day, weekly a 7-day window, monthly a 33-day window
/// (`startDate`/`endDate` a request actually resolved to, e.g. weekly
/// `2026-09-17` to `2026-09-23`, monthly `2026-08-22` to `2026-09-23`).
const _windowDaysByPeriod = [1, 7, 33];

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

  /// Switching tabs always re-anchors on `today` (rather than keeping
  /// whatever date the previous tab had navigated to) and drops any
  /// explicit calendar-month range, so tapping Weekly fires the current
  /// 7-day window ending today and tapping Monthly fires the current
  /// 33-day window ending today, immediately.
  Future<void> _onSelectPeriod(
    SelectPeriod event,
    Emitter<AmolDashboardState> emit,
  ) async {
    if (state.selectedPeriod == event.period) return;
    emit(
      state.copyWith(
        selectedPeriod: event.period,
        date: state.today,
        clearRangeStart: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _onShiftDate(
    ShiftDate event,
    Emitter<AmolDashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        date: state.date.add(event.step * event.direction),
        clearRangeStart: true,
      ),
    );
    await _load(emit);
  }

  /// Jumps straight to one calendar month, e.g. picked from the monthly
  /// tab's "last 12 months" dropdown. The current month keeps the normal
  /// 33-day sliding window ending today (matching what tapping the Monthly
  /// tab itself shows); any other month uses its true calendar bounds
  /// (1st to last day) instead of forcing it through the sliding window.
  Future<void> _onSelectMonth(
    SelectMonth event,
    Emitter<AmolDashboardState> emit,
  ) async {
    final isCurrentMonth =
        event.month.year == state.today.year &&
        event.month.month == state.today.month;
    if (isCurrentMonth) {
      emit(state.copyWith(date: state.today, clearRangeStart: true));
    } else {
      emit(
        state.copyWith(
          date: _lastDayOfMonth(event.month),
          rangeStart: DateTime(event.month.year, event.month.month, 1),
        ),
      );
    }
    await _load(emit);
  }

  /// Hits `GET /amol/analytics/graph?timeframe=[timeframe]&startDate=[..]&endDate=[..]&offset=[..]`
  /// for the state's current window, e.g. weekly ending 2026-09-23 ->
  /// `timeframe=weekly&startDate=2026-09-17&endDate=2026-09-23&offset=0`;
  /// shifting a week back -> `...&startDate=2026-09-10&endDate=2026-09-16&offset=1`.
  Future<void> _load(Emitter<AmolDashboardState> emit) async {
    final requestId = ++_requestId;
    emit(state.copyWith(status: AmolDashboardStatus.loading));

    final endDate = state.date;
    final windowDays = _windowDaysByPeriod[state.selectedPeriod];
    final startDate =
        state.rangeStart ?? endDate.subtract(Duration(days: windowDays - 1));
    final isDaily = state.selectedPeriod == 0;
    // Only meaningful for the regular sliding-window navigation (not an
    // explicit calendar-month jump, and not daily, which the server takes
    // no offset for at all).
    final offset = (isDaily || state.rangeStart != null)
        ? null
        : (state.today.difference(endDate).inDays / windowDays).round();

    final result = await _getGraph(
      startDate: _isoDate(startDate),
      endDate: _isoDate(endDate),
      timeframe: _timeframeByPeriod[state.selectedPeriod],
      offset: offset,
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
