import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_details.dart';

import 'hadith_detail_event.dart';
import 'hadith_detail_state.dart';

export 'hadith_detail_event.dart';
export 'hadith_detail_state.dart';

class HadithDetailBloc extends Bloc<HadithDetailEvent, HadithDetailState> {
  HadithDetailBloc(this._getHadithDetails) : super(const HadithDetailState()) {
    on<LoadHadithDetails>(_onLoad);
    on<LoadMoreHadithDetails>(_onLoadMore);
  }

  final GetHadithDetails _getHadithDetails;
  String? _subCategoryId;
  String? _bookId;
  String? _planId;

  /// Bumped for every fresh first-page load so a slow, superseded response
  /// can't overwrite a newer one.
  int _generation = 0;

  Future<void> _onLoad(
    LoadHadithDetails event,
    Emitter<HadithDetailState> emit,
  ) async {
    _subCategoryId = event.subCategoryId;
    _bookId = event.bookId;
    _planId = event.planId;
    final generation = ++_generation;
    emit(const HadithDetailState(status: HadithDetailStatus.loading));
    final result = await _getHadithDetails(
      subCategoryId: _subCategoryId,
      bookId: _bookId,
      planId: _planId,
    );
    if (generation != _generation) return;
    result.fold(
      (failure) => emit(
        HadithDetailState(status: HadithDetailStatus.failure, failure: failure),
      ),
      (page) => emit(
        HadithDetailState(
          status: HadithDetailStatus.success,
          hadiths: page.hadiths,
          page: page.page,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreHadithDetails event,
    Emitter<HadithDetailState> emit,
  ) async {
    if (state.status != HadithDetailStatus.success ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true, clearLoadMoreFailure: true));
    final result = await _getHadithDetails(
      subCategoryId: _subCategoryId,
      bookId: _bookId,
      planId: _planId,
      page: state.page + 1,
    );
    if (generation != _generation) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingMore: false, loadMoreFailure: failure)),
      (page) => emit(
        state.copyWith(
          isLoadingMore: false,
          hadiths: [...state.hadiths, ...page.hadiths],
          page: page.page,
          hasMore: page.hasMore,
        ),
      ),
    );
  }
}
