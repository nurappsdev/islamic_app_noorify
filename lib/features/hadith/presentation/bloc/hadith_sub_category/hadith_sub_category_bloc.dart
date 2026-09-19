import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_sub_categories.dart';

import 'hadith_sub_category_event.dart';
import 'hadith_sub_category_state.dart';

export 'hadith_sub_category_event.dart';
export 'hadith_sub_category_state.dart';

class HadithSubCategoryBloc
    extends Bloc<HadithSubCategoryEvent, HadithSubCategoryState> {
  HadithSubCategoryBloc(this._getSubCategories)
    : super(const HadithSubCategoryState()) {
    on<LoadHadithSubCategories>(_onLoad);
    on<SearchHadithSubCategories>(_onSearch);
    on<LoadMoreHadithSubCategories>(_onLoadMore);
  }

  final GetHadithSubCategories _getSubCategories;
  String _categoryId = '';
  String _searchTerm = '';

  /// Bumped for every fresh first-page load so a slow, superseded response
  /// (e.g. from an earlier search term) can't overwrite a newer one.
  int _generation = 0;

  Future<void> _onLoad(
    LoadHadithSubCategories event,
    Emitter<HadithSubCategoryState> emit,
  ) {
    _categoryId = event.categoryId;
    _searchTerm = '';
    return _loadFirstPage(emit);
  }

  Future<void> _onSearch(
    SearchHadithSubCategories event,
    Emitter<HadithSubCategoryState> emit,
  ) {
    final term = event.term.trim();
    if (term == _searchTerm) return Future.value();
    _searchTerm = term;
    return _loadFirstPage(emit);
  }

  Future<void> _loadFirstPage(Emitter<HadithSubCategoryState> emit) async {
    final generation = ++_generation;
    emit(const HadithSubCategoryState(status: HadithSubCategoryStatus.loading));
    final result = await _getSubCategories(
      _categoryId,
      searchTerm: _searchTerm,
    );
    if (generation != _generation) return;
    result.fold(
      (failure) => emit(
        HadithSubCategoryState(
          status: HadithSubCategoryStatus.failure,
          failure: failure,
        ),
      ),
      (page) => emit(
        HadithSubCategoryState(
          status: HadithSubCategoryStatus.success,
          subCategories: page.subCategories,
          page: page.page,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreHadithSubCategories event,
    Emitter<HadithSubCategoryState> emit,
  ) async {
    if (state.status != HadithSubCategoryStatus.success ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true, clearLoadMoreFailure: true));
    final result = await _getSubCategories(
      _categoryId,
      page: state.page + 1,
      searchTerm: _searchTerm,
    );
    if (generation != _generation) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingMore: false, loadMoreFailure: failure)),
      (page) => emit(
        state.copyWith(
          isLoadingMore: false,
          subCategories: [...state.subCategories, ...page.subCategories],
          page: page.page,
          hasMore: page.hasMore,
        ),
      ),
    );
  }
}
