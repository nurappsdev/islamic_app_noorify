import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/learning/domain/entities/article.dart';
import 'package:tuhfatul_muslim/features/learning/domain/usecases/get_article_categories.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/bloc/learning_paged_state.dart';

export 'package:tuhfatul_muslim/features/learning/presentation/bloc/learning_paged_state.dart';

typedef ArticleCategoriesState = LearningPagedState<ArticleCategory>;

abstract class ArticleCategoriesEvent {
  const ArticleCategoriesEvent();
}

/// Fetches the first page; also used by Try Again.
class LoadArticleCategories extends ArticleCategoriesEvent {
  const LoadArticleCategories();
}

/// Fetches the next page. Ignored while one is loading or after the last.
class LoadMoreArticleCategories extends ArticleCategoriesEvent {
  const LoadMoreArticleCategories();
}

class ArticleCategoriesBloc
    extends Bloc<ArticleCategoriesEvent, ArticleCategoriesState> {
  ArticleCategoriesBloc(this._getCategories, {this.pageSize = 10})
    : super(const ArticleCategoriesState()) {
    on<LoadArticleCategories>(_onLoad);
    on<LoadMoreArticleCategories>(_onLoadMore);
  }

  final GetArticleCategories _getCategories;
  final int pageSize;

  /// Bumped for every first-page load, so a slow response it replaced
  /// cannot overwrite it.
  int _generation = 0;

  Future<void> _onLoad(
    LoadArticleCategories event,
    Emitter<ArticleCategoriesState> emit,
  ) async {
    final generation = ++_generation;
    emit(const ArticleCategoriesState());
    final result = await _getCategories(page: 1, limit: pageSize);
    if (generation != _generation) return;
    result.fold(
      (failure) => emit(
        ArticleCategoriesState(
          status: LearningLoadStatus.failure,
          failure: failure,
        ),
      ),
      (page) => emit(
        ArticleCategoriesState(
          status: LearningLoadStatus.success,
          items: page.categories,
          page: page.meta.page,
          hasMore: page.meta.hasMore,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreArticleCategories event,
    Emitter<ArticleCategoriesState> emit,
  ) async {
    if (!state.canLoadMore) return;
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true, clearLoadMoreFailure: true));
    final result = await _getCategories(page: state.page + 1, limit: pageSize);
    if (generation != _generation) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingMore: false, loadMoreFailure: failure)),
      (page) => emit(
        state.copyWith(
          isLoadingMore: false,
          items: appendPage(state.items, page.categories, (c) => c.id),
          page: page.meta.page,
          hasMore: page.meta.hasMore,
        ),
      ),
    );
  }
}
