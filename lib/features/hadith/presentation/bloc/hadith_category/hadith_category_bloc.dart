import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_categories.dart';

import 'hadith_category_event.dart';
import 'hadith_category_state.dart';

export 'hadith_category_event.dart';
export 'hadith_category_state.dart';

class HadithCategoryBloc
    extends Bloc<HadithCategoryEvent, HadithCategoryState> {
  HadithCategoryBloc(this._getCategories) : super(const HadithCategoryState()) {
    on<LoadHadithCategories>(_onLoad);
    on<LoadMoreHadithCategories>(_onLoadMore);
  }

  final GetHadithCategories _getCategories;
  String _bookId = '';

  Future<void> _onLoad(
    LoadHadithCategories event,
    Emitter<HadithCategoryState> emit,
  ) async {
    _bookId = event.bookId;
    emit(const HadithCategoryState(status: HadithCategoryStatus.loading));
    final result = await _getCategories(_bookId);
    result.fold(
      (failure) => emit(
        HadithCategoryState(
          status: HadithCategoryStatus.failure,
          failure: failure,
        ),
      ),
      (page) => emit(
        HadithCategoryState(
          status: HadithCategoryStatus.success,
          categories: page.categories,
          page: page.page,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreHadithCategories event,
    Emitter<HadithCategoryState> emit,
  ) async {
    if (state.status != HadithCategoryStatus.success ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true, clearLoadMoreFailure: true));
    final result = await _getCategories(_bookId, page: state.page + 1);
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingMore: false, loadMoreFailure: failure)),
      (page) => emit(
        state.copyWith(
          isLoadingMore: false,
          categories: [...state.categories, ...page.categories],
          page: page.page,
          hasMore: page.hasMore,
        ),
      ),
    );
  }
}
