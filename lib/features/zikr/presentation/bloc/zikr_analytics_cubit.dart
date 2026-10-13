import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/zikr/data/models/zikr_api_models.dart';
import 'package:tuhfatul_muslim/features/zikr/domain/repositories/zikr_repository.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/bloc/zikr_home_cubit.dart';

class ZikrAnalyticsState {
  const ZikrAnalyticsState({
    this.status = ZikrLoadStatus.initial,
    this.period = 'daily',
    this.offset = 0,
    this.analytics,
    this.history = const [],
    this.page = 1,
    this.totalPage = 1,
    this.error,
  });
  final ZikrLoadStatus status;
  final String period;

  /// Periods back from the current one (0 = current day/week/month, 1 = one
  /// back, ...). Stepping "next" can only ever return to 0 — see
  /// [ZikrAnalyticsCubit.shiftOffset].
  final int offset;
  final TasbihAnalyticsResponse? analytics;
  final List<ZikrSessionHistory> history;
  final int page;
  final int totalPage;
  final String? error;
  ZikrAnalyticsState copyWith({
    ZikrLoadStatus? status,
    String? period,
    int? offset,
    TasbihAnalyticsResponse? analytics,
    List<ZikrSessionHistory>? history,
    int? page,
    int? totalPage,
    String? error,
    bool clearError = false,
  }) => ZikrAnalyticsState(
    status: status ?? this.status,
    period: period ?? this.period,
    offset: offset ?? this.offset,
    analytics: analytics ?? this.analytics,
    history: history ?? this.history,
    page: page ?? this.page,
    totalPage: totalPage ?? this.totalPage,
    error: clearError ? null : (error ?? this.error),
  );
}

class ZikrAnalyticsCubit extends Cubit<ZikrAnalyticsState> {
  ZikrAnalyticsCubit(this._repository) : super(const ZikrAnalyticsState());
  final ZikrRepository _repository;
  int _requestId = 0;

  /// Switching period always re-anchors on the current day/week/month
  /// (`offset: 0`) rather than keeping whatever offset the previous period
  /// had navigated to.
  Future<void> load({String? period}) async {
    final nextPeriod = period ?? state.period;
    final nextOffset = period != null && period != state.period
        ? 0
        : state.offset;
    await _load(period: nextPeriod, offset: nextOffset);
  }

  /// Steps the current period's window back (`direction: -1`, offset grows)
  /// or forward (`direction: 1`, offset shrinks) one day/week/month. Forward
  /// is clamped at `offset: 0` (the current one) — never past it.
  Future<void> shiftOffset(int direction) async {
    final nextOffset = (state.offset - direction).clamp(0, 1 << 30);
    if (nextOffset == state.offset) return;
    await _load(period: state.period, offset: nextOffset);
  }

  /// Jumps straight to the day (Daily) or the 7-day window containing it
  /// (Weekly), from a date picked on [_ZikrDateNavigator]. Converts the pick
  /// into the equivalent `offset` so the arrows keep stepping from here;
  /// [_load] turns that back into the explicit `from`/`to` dates actually
  /// sent. Ignores a future date — same limit the forward arrow enforces.
  Future<void> jumpToDate(DateTime date) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = todayDate.difference(target).inDays;
    if (diffDays < 0) return;
    final nextOffset = state.period == 'weekly' ? diffDays ~/ 7 : diffDays;
    await _load(period: state.period, offset: nextOffset);
  }

  /// Monthly's own filter: `month: null` is the default "Last 30 days" chip
  /// (today and the 29 days before it); a picked month sends that calendar
  /// month's first and last day instead. Unlike Daily/Weekly there's no
  /// `offset` for Monthly — each chip names an explicit range directly.
  Future<void> loadMonthly({DateTime? month}) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final DateTime from, to;
    if (month == null) {
      to = todayDate;
      from = todayDate.subtract(const Duration(days: 29));
    } else {
      from = DateTime(month.year, month.month);
      to = DateTime(month.year, month.month + 1).subtract(
        const Duration(days: 1),
      );
    }
    await _load(
      period: 'monthly',
      offset: 0,
      from: _isoDate(from),
      to: _isoDate(to),
    );
  }

  static String _isoDate(DateTime date) {
    String pad2(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${pad2(date.month)}-${pad2(date.day)}';
  }

  /// Daily/Weekly always query an explicit `from`/`to` range computed from
  /// `offset` (day 0 = today; week 0 = the 7 days ending today), rather than
  /// sending `offset` itself — confirmed against the live API as the
  /// reliable shape (`isCustomRange: true` in its response). Monthly builds
  /// its own range directly in [loadMonthly] instead of going through here.
  (String?, String?) _rangeFor(String period, int offset) {
    if (period != 'daily' && period != 'weekly') return (null, null);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (period == 'daily') {
      final day = todayDate.subtract(Duration(days: offset));
      return (_isoDate(day), _isoDate(day));
    }
    final end = todayDate.subtract(Duration(days: offset * 7));
    final start = end.subtract(const Duration(days: 6));
    return (_isoDate(start), _isoDate(end));
  }

  Future<void> _load({
    required String period,
    required int offset,
    String? from,
    String? to,
  }) async {
    final requestId = ++_requestId;
    emit(
      state.copyWith(
        status: ZikrLoadStatus.loading,
        period: period,
        offset: offset,
        clearError: true,
      ),
    );
    try {
      final range = from == null && to == null
          ? _rangeFor(period, offset)
          : (from, to);
      final result = await _repository.getAnalytics(
        period,
        offset: offset,
        from: range.$1,
        to: range.$2,
      );
      if (requestId != _requestId) return;
      emit(state.copyWith(status: ZikrLoadStatus.success, analytics: result));
    } catch (error) {
      if (requestId == _requestId) {
        emit(state.copyWith(status: ZikrLoadStatus.failure, error: '$error'));
      }
    }
  }

  Future<void> loadHistory({bool nextPage = false}) async {
    if (nextPage && state.page >= state.totalPage) return;
    final page = nextPage ? state.page + 1 : 1;
    try {
      final result = await _repository.getHistory(page: page, limit: 20);
      emit(
        state.copyWith(
          history: nextPage
              ? [...state.history, ...result.items]
              : result.items,
          page: result.meta.page,
          totalPage: result.meta.totalPage,
        ),
      );
    } catch (error) {
      emit(state.copyWith(error: '$error'));
    }
  }
}
