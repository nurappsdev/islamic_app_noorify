import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/zikr/data/models/zikr_api_models.dart';
import 'package:tuhfatul_muslim/features/zikr/domain/repositories/zikr_repository.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/bloc/zikr_home_cubit.dart';

class ZikrAnalyticsState {
  const ZikrAnalyticsState({
    this.status = ZikrLoadStatus.initial,
    this.period = 'daily',
    this.analytics,
    this.history = const [],
    this.page = 1,
    this.totalPage = 1,
    this.error,
  });
  final ZikrLoadStatus status;
  final String period;
  final TasbihAnalyticsResponse? analytics;
  final List<ZikrSessionHistory> history;
  final int page;
  final int totalPage;
  final String? error;
  ZikrAnalyticsState copyWith({
    ZikrLoadStatus? status,
    String? period,
    TasbihAnalyticsResponse? analytics,
    List<ZikrSessionHistory>? history,
    int? page,
    int? totalPage,
    String? error,
    bool clearError = false,
  }) => ZikrAnalyticsState(
    status: status ?? this.status,
    period: period ?? this.period,
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

  Future<void> load({String? period}) async {
    final nextPeriod = period ?? state.period;
    final requestId = ++_requestId;
    emit(
      state.copyWith(
        status: ZikrLoadStatus.loading,
        period: nextPeriod,
        clearError: true,
      ),
    );
    try {
      final result = await _repository.getAnalytics(nextPeriod);
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
