import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';

enum DuaPlannerStatus { initial, loading, success, failure }

/// One tab's own list, kept in memory so switching tabs shows its plans at
/// once instead of waiting on `GET /duas/planner/plans`.
class DuaPlannerTabData {
  const DuaPlannerTabData({
    this.plans = const [],
    this.page = 1,
    this.hasMore = false,
    this.total,
    this.status = DuaPlannerStatus.initial,
    this.loadingMore = false,
    this.error,
  });

  final List<DuaPlan> plans;
  final int page;
  final bool hasMore;

  /// The tab's count as the API reported it, shown beside its label.
  final int? total;

  final DuaPlannerStatus status;
  final bool loadingMore;
  final String? error;

  /// Whether this tab has a usable list already — an empty tab counts too,
  /// so a user with no completed plans is not made to wait twice.
  bool get isLoaded => status == DuaPlannerStatus.success;

  DuaPlannerTabData copyWith({
    List<DuaPlan>? plans,
    int? page,
    bool? hasMore,
    int? total,
    DuaPlannerStatus? status,
    bool? loadingMore,
    String? error,
    bool clearError = false,
  }) => DuaPlannerTabData(
    plans: plans ?? this.plans,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    total: total ?? this.total,
    status: status ?? this.status,
    loadingMore: loadingMore ?? this.loadingMore,
    error: clearError ? null : (error ?? this.error),
  );
}

class DuaPlannerState {
  const DuaPlannerState({
    this.tab = 0,
    this.tabs = const {},
    this.calendar = const {},
  });

  /// 0 = "My Plan" (in progress), 1 = "Complete Plan".
  final int tab;

  /// Both tabs' lists, by API status.
  final Map<String, DuaPlannerTabData> tabs;

  /// Reading status per `yyyy-MM-dd`, from
  /// `GET /duas/reading/calendar?from=...&to=...` — the week strip's dots.
  /// It depends on the week alone, never on the tab.
  final Map<String, DuaCalendarDay> calendar;

  static const inProgress = 'in_progress';
  static const completed = 'completed';

  String get statusKey => tab == 1 ? completed : inProgress;
  DuaPlannerTabData get current => tabs[statusKey] ?? const DuaPlannerTabData();

  List<DuaPlan> get plans => current.plans;
  DuaPlannerStatus get status => current.status;
  int get page => current.page;
  bool get hasMore => current.hasMore;
  bool get loadingMore => current.loadingMore;
  String? get error => current.error;

  /// Plan totals per tab, for the labels.
  Map<String, int> get counts => {
    for (final entry in tabs.entries)
      if (entry.value.total != null) entry.key: entry.value.total!,
  };

  DuaPlannerState copyWith({
    int? tab,
    Map<String, DuaPlannerTabData>? tabs,
    Map<String, DuaCalendarDay>? calendar,
  }) => DuaPlannerState(
    tab: tab ?? this.tab,
    tabs: tabs ?? this.tabs,
    calendar: calendar ?? this.calendar,
  );

  DuaPlannerState withTab(String status, DuaPlannerTabData data) =>
      copyWith(tabs: {...tabs, status: data});
}

/// Loads the Dua planner's "My Plan" / "Complete Plan" tabs, 10 at a time
/// (`GET /duas/planner/plans?status=...&page=...&limit=10`), design
/// `devImg/img_35.png`.
///
/// Both tabs are cached in [DuaPlannerState.tabs]: the first load fetches the
/// visible tab and the week's calendar in parallel, then quietly prefetches
/// the other tab, so a tab switch is instant and costs no calendar request.
class DuaPlannerCubit extends Cubit<DuaPlannerState> {
  DuaPlannerCubit(this._repository) : super(const DuaPlannerState());
  final DuaRepository _repository;

  static const _limit = 10;
  static const _oneDay = Duration(days: 1);

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _apiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _other(String status) => status == DuaPlannerState.completed
      ? DuaPlannerState.inProgress
      : DuaPlannerState.completed;

  /// Identifies the newest request per tab. A response from an older request
  /// must not overwrite a newer result when it eventually arrives.
  final Map<String, int> _generations = {};

  int _bump(String status) =>
      _generations[status] = (_generations[status] ?? 0) + 1;

  bool _isStale(String status, int generation) =>
      isClosed || _generations[status] != generation;

  /// The days the calendar endpoint has already been asked for, so moving
  /// across the same week twice costs nothing.
  final Set<String> _requestedDays = {};

  /// The week the strip shows; [load] fetches its dots alongside the plans.
  DateTime _windowFrom = _dateOnly(
    DateTime.now().subtract(const Duration(days: 3)),
  );
  DateTime _windowTo = _dateOnly(DateTime.now().add(const Duration(days: 3)));

  /// The dots for [from]...[to], unless every day in it is already known.
  /// Called by the screen when the week strip moves — and only then.
  Future<void> loadCalendar(DateTime from, DateTime to) async {
    _windowFrom = _dateOnly(from);
    _windowTo = _dateOnly(to);
    if (isClosed || _isCovered(_windowFrom, _windowTo)) return;
    final days = await _calendarDays(_windowFrom, _windowTo);
    if (isClosed || days.isEmpty) return;
    emit(state.copyWith(calendar: {...state.calendar, ...days}));
  }

  bool _isCovered(DateTime from, DateTime to) {
    for (var day = from; !day.isAfter(to); day = day.add(_oneDay)) {
      if (!_requestedDays.contains(_apiDate(day))) return false;
    }
    return true;
  }

  /// A failed calendar never fails the screen: the strip simply shows no
  /// dots for those days, and the next navigation retries them.
  Future<Map<String, DuaCalendarDay>> _calendarDays(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final calendar = await _repository.getReadingCalendar(
        from: _apiDate(from),
        to: _apiDate(to),
      );
      for (var day = from; !day.isAfter(to); day = day.add(_oneDay)) {
        _requestedDays.add(_apiDate(day));
      }
      return {for (final day in calendar.days) day.date.split('T').first: day};
    } catch (_) {
      return const {};
    }
  }

  /// Shows a tab at once from memory. A tab that has never loaded fetches its
  /// first page (the screen shows a shimmer meanwhile); a cached one is
  /// refreshed quietly behind the list that is already on screen. Either way
  /// no calendar request goes out — the dots depend on the week, not the tab.
  Future<void> selectTab(int tab) async {
    if (isClosed || tab == state.tab) return;
    emit(state.copyWith(tab: tab));
    final status = state.statusKey;
    await _fetchTab(status, silent: state.tabs[status]?.isLoaded ?? false);
  }

  /// The visible tab and the week's dots in parallel, then the other tab in
  /// the background. Used on open, on pull-to-refresh and after a plan was
  /// created, edited or deleted.
  Future<void> load() async {
    if (isClosed) return;
    final status = state.statusKey;
    final generation = _bump(status);
    emit(
      state.withTab(
        status,
        state.current.copyWith(
          status: DuaPlannerStatus.loading,
          clearError: true,
        ),
      ),
    );
    try {
      final (result, days) = await (
        _repository.getPlans(status: status, page: 1, limit: _limit),
        _calendarDays(_windowFrom, _windowTo),
      ).wait;
      if (_isStale(status, generation)) return;
      emit(
        state
            .copyWith(calendar: {...state.calendar, ...days})
            .withTab(status, _loaded(result)),
      );
      unawaited(_fetchTab(_other(status), silent: true));
    } catch (error) {
      if (_isStale(status, generation)) return;
      emit(
        state.withTab(
          status,
          state.tabs[status]?.copyWith(
                status: DuaPlannerStatus.failure,
                error: '$error',
              ) ??
              DuaPlannerTabData(
                status: DuaPlannerStatus.failure,
                error: '$error',
              ),
        ),
      );
    }
  }

  /// Reloads the tab in front of the user and refreshes the other one in the
  /// background — both are stale once a plan was created, edited or deleted.
  Future<void> refreshAll({int? tab}) async {
    if (isClosed) return;
    if (tab != null && tab != state.tab) emit(state.copyWith(tab: tab));
    final status = state.statusKey;
    await _fetchTab(status);
    unawaited(_fetchTab(_other(status), silent: true));
  }

  DuaPlannerTabData _loaded(DuaPlanPage result) => DuaPlannerTabData(
    plans: result.plans,
    page: result.page,
    hasMore: result.hasMore,
    total: result.total,
    status: DuaPlannerStatus.success,
  );

  /// One tab's first page. A silent fetch leaves the cached list (and a
  /// failure) untouched until the new one arrives, so nothing flickers.
  Future<void> _fetchTab(String status, {bool silent = false}) async {
    if (isClosed) return;
    final generation = _bump(status);
    final cached = state.tabs[status] ?? const DuaPlannerTabData();
    if (!silent) {
      emit(
        state.withTab(
          status,
          cached.copyWith(status: DuaPlannerStatus.loading, clearError: true),
        ),
      );
    }
    try {
      final result = await _repository.getPlans(
        status: status,
        page: 1,
        limit: _limit,
      );
      if (_isStale(status, generation)) return;
      emit(state.withTab(status, _loaded(result)));
    } catch (error) {
      if (_isStale(status, generation) || silent) return;
      emit(
        state.withTab(
          status,
          cached.copyWith(status: DuaPlannerStatus.failure, error: '$error'),
        ),
      );
    }
  }

  /// The next page of the visible tab, appended — ignored while a load is
  /// already in flight or there isn't one.
  Future<void> loadMore() async {
    if (isClosed || state.loadingMore || !state.hasMore) return;
    final status = state.statusKey;
    final generation = _generations[status];
    final cached = state.current;
    final nextPage = cached.page + 1;
    emit(state.withTab(status, cached.copyWith(loadingMore: true)));
    try {
      final result = await _repository.getPlans(
        status: status,
        page: nextPage,
        limit: _limit,
      );
      if (isClosed || _generations[status] != generation) return;
      emit(
        state.withTab(
          status,
          cached.copyWith(
            plans: [...cached.plans, ...result.plans],
            page: result.page,
            hasMore: result.hasMore,
            total: result.total,
            loadingMore: false,
            status: DuaPlannerStatus.success,
          ),
        ),
      );
    } catch (_) {
      // A failed "load more" leaves the existing page visible; the user can
      // just scroll again to retry.
      if (isClosed || _generations[status] != generation) return;
      emit(state.withTab(status, state.current.copyWith(loadingMore: false)));
    }
  }

  /// Deletes a plan, then refreshes both tabs' lists.
  Future<void> delete(String id) async {
    await _repository.deletePlan(id);
    if (isClosed) return;
    await refreshAll();
  }
}
