import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';

enum DuaPlannerStatus { initial, loading, success, failure }

class DuaPlannerState {
  const DuaPlannerState({
    this.status = DuaPlannerStatus.initial,
    this.tab = 0,
    this.plans = const [],
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.counts = const {},
    this.calendar = const {},
    this.error,
  });

  /// 0 = "My Plan" (in progress), 1 = "Complete Plan".
  final DuaPlannerStatus status;
  final int tab;
  final List<DuaPlan> plans;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  /// How many plans each tab holds, keyed by API status (`in_progress`,
  /// `completed`) — the design shows the count beside each tab label, so the
  /// other tab's total is fetched alongside the visible one.
  final Map<String, int> counts;

  /// Reading status per `yyyy-MM-dd`, from
  /// `GET /duas/reading/calendar?from=...&to=...` — the week strip's dots.
  final Map<String, DuaCalendarDay> calendar;

  final String? error;

  DuaPlannerState copyWith({
    DuaPlannerStatus? status,
    int? tab,
    List<DuaPlan>? plans,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    Map<String, int>? counts,
    Map<String, DuaCalendarDay>? calendar,
    String? error,
    bool clearError = false,
  }) => DuaPlannerState(
    status: status ?? this.status,
    tab: tab ?? this.tab,
    plans: plans ?? this.plans,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    counts: counts ?? this.counts,
    calendar: calendar ?? this.calendar,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Loads the Dua planner's "My Plan" / "Complete Plan" tabs, 10 at a time
/// (`GET /duas/planner/plans?status=...&page=...&limit=10`), design
/// `devImg/img_7.png`.
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

  /// Identifies the newest first-page request. A response from an older tab
  /// or refresh must not overwrite the newer result when it eventually
  /// arrives.
  int _loadGeneration = 0;

  static const _inProgress = 'in_progress';
  static const _completed = 'completed';

  String get _status => state.tab == 1 ? _completed : _inProgress;

  /// Plans in the tab the user is *not* on, so its label can carry a count
  /// too. One cheap `limit=1` request, and a failure just leaves the count
  /// absent.
  Future<void> _loadOtherCount(String status) async {
    final other = status == _completed ? _inProgress : _completed;
    try {
      final page = await _repository.getPlans(status: other, page: 1, limit: 1);
      if (isClosed) return;
      emit(state.copyWith(counts: {...state.counts, other: page.total}));
    } catch (_) {
      // The tab simply shows no count.
    }
  }

  Future<void> selectTab(int tab) async {
    if (isClosed) return;
    emit(state.copyWith(tab: tab));
    await load();
  }

  /// The days the calendar endpoint has already been asked for, so moving
  /// across the same week twice costs nothing.
  final Set<String> _requestedDays = {};

  /// The week the strip shows; [load] fetches its dots alongside the plans.
  DateTime _windowFrom = _dateOnly(
    DateTime.now().subtract(const Duration(days: 3)),
  );
  DateTime _windowTo = _dateOnly(DateTime.now().add(const Duration(days: 3)));

  /// The dots for [from]...[to], unless every day in it is already known.
  /// Called by the screen whenever the week strip moves.
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

  /// The first page — replaces whatever was loaded before. The plans and the
  /// week's calendar dots are fetched in parallel, so the screen waits for
  /// one round trip rather than two.
  Future<void> load() async {
    if (isClosed) return;
    final generation = ++_loadGeneration;
    final status = _status;
    emit(state.copyWith(status: DuaPlannerStatus.loading, clearError: true));
    try {
      final (result, days) = await (
        _repository.getPlans(status: status, page: 1, limit: _limit),
        _calendarDays(_windowFrom, _windowTo),
      ).wait;
      if (isClosed || generation != _loadGeneration) return;
      emit(
        state.copyWith(
          status: DuaPlannerStatus.success,
          plans: result.plans,
          page: result.page,
          hasMore: result.hasMore,
          counts: {...state.counts, status: result.total},
          calendar: {...state.calendar, ...days},
        ),
      );
      unawaited(_loadOtherCount(status));
    } catch (error) {
      if (isClosed || generation != _loadGeneration) return;
      emit(state.copyWith(status: DuaPlannerStatus.failure, error: '$error'));
    }
  }

  /// The next page, appended — ignored while a load is already in flight or
  /// there isn't one.
  Future<void> loadMore() async {
    if (isClosed || state.loadingMore || !state.hasMore) return;
    final generation = _loadGeneration;
    final status = _status;
    final nextPage = state.page + 1;
    emit(state.copyWith(loadingMore: true));
    try {
      final result = await _repository.getPlans(
        status: status,
        page: nextPage,
        limit: _limit,
      );
      if (isClosed || generation != _loadGeneration) return;
      emit(
        state.copyWith(
          plans: [...state.plans, ...result.plans],
          page: result.page,
          hasMore: result.hasMore,
          loadingMore: false,
        ),
      );
    } catch (_) {
      // A failed "load more" leaves the existing page visible; the user can
      // just scroll again to retry.
      if (isClosed || generation != _loadGeneration) return;
      emit(state.copyWith(loadingMore: false));
    }
  }

  /// Deletes a plan, then reloads the current tab's first page.
  Future<void> delete(String id) async {
    await _repository.deletePlan(id);
    if (isClosed) return;
    await load();
  }
}
