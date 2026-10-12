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

  Future<void> _load({required String period, required int offset}) async {
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
      final result = await _repository.getAnalytics(period, offset: offset);
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
