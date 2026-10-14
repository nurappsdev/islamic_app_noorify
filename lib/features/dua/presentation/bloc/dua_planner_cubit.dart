import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
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
    this.error,
  });

  /// 0 = "My Plan" (in progress), 1 = "Complete Plan".
  final DuaPlannerStatus status;
  final int tab;
  final List<DuaPlan> plans;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final String? error;

  DuaPlannerState copyWith({
    DuaPlannerStatus? status,
    int? tab,
    List<DuaPlan>? plans,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? error,
    bool clearError = false,
  }) => DuaPlannerState(
    status: status ?? this.status,
    tab: tab ?? this.tab,
    plans: plans ?? this.plans,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
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

  String get _status => state.tab == 1 ? 'completed' : 'in_progress';

  Future<void> selectTab(int tab) async {
    emit(state.copyWith(tab: tab));
    await load();
  }

  /// The first page — replaces whatever was loaded before.
  Future<void> load() async {
    emit(state.copyWith(status: DuaPlannerStatus.loading, clearError: true));
    try {
      final result = await _repository.getPlans(
        status: _status,
        page: 1,
        limit: _limit,
      );
      emit(
        state.copyWith(
          status: DuaPlannerStatus.success,
          plans: result.plans,
          page: result.page,
          hasMore: result.hasMore,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: DuaPlannerStatus.failure, error: '$error'));
    }
  }

  /// The next page, appended — ignored while a load is already in flight or
  /// there isn't one.
  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final result = await _repository.getPlans(
        status: _status,
        page: state.page + 1,
        limit: _limit,
      );
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
      emit(state.copyWith(loadingMore: false));
    }
  }

  /// Deletes a plan, then reloads the current tab's first page.
  Future<void> delete(String id) async {
    await _repository.deletePlan(id);
    await load();
  }
}
