import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_plans.dart';

import 'hadith_plans_event.dart';
import 'hadith_plans_state.dart';

export 'hadith_plans_event.dart';
export 'hadith_plans_state.dart';

/// The user's hadith plans with the given [status] (`in_progress` for the
/// "My Plan" tab), 10 per page.
class HadithPlansBloc extends Bloc<HadithPlansEvent, HadithPlansState> {
  HadithPlansBloc(this._getPlans, {this.status})
    : super(const HadithPlansState()) {
    on<LoadHadithPlans>(_onLoad);
    on<LoadMoreHadithPlans>(_onLoadMore);
  }

  final GetHadithPlans _getPlans;
  final String? status;

  /// Bumped for every fresh first-page load so a slow, superseded response
  /// can't overwrite a newer one.
  int _generation = 0;

  Future<void> _onLoad(
    LoadHadithPlans event,
    Emitter<HadithPlansState> emit,
  ) async {
    final generation = ++_generation;
    emit(const HadithPlansState(status: HadithPlansStatus.loading));
    final result = await _getPlans(status: status);
    if (generation != _generation || emit.isDone) return;
    result.fold(
      (failure) => emit(
        HadithPlansState(status: HadithPlansStatus.failure, failure: failure),
      ),
      (page) => emit(
        HadithPlansState(
          status: HadithPlansStatus.success,
          plans: page.plans,
          page: page.page,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreHadithPlans event,
    Emitter<HadithPlansState> emit,
  ) async {
    if (state.status != HadithPlansStatus.success ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true, clearLoadMoreFailure: true));
    final result = await _getPlans(status: status, page: state.page + 1);
    if (generation != _generation || emit.isDone) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingMore: false, loadMoreFailure: failure)),
      (page) => emit(
        state.copyWith(
          isLoadingMore: false,
          plans: [...state.plans, ...page.plans],
          page: page.page,
          hasMore: page.hasMore,
        ),
      ),
    );
  }
}

/// The user's completed plans (`status: completed`) for the "My Complete"
/// tab — a distinct type from [HadithPlansBloc] so both can be provided at
/// once and read unambiguously by type.
class HadithCompletedPlansBloc extends HadithPlansBloc {
  // Not a super parameter: `status` is fixed here, not forwarded from a
  // constructor argument, so the super call must stay explicit.
  // ignore: use_super_parameters
  HadithCompletedPlansBloc(GetHadithPlans getPlans)
    : super(getPlans, status: 'completed');
}
