import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/learning/domain/entities/article.dart';
import 'package:islami_app_noorify/features/learning/domain/usecases/get_articles.dart';
import 'package:islami_app_noorify/features/learning/presentation/bloc/learning_paged_state.dart';

export 'package:islami_app_noorify/features/learning/presentation/bloc/learning_paged_state.dart';

typedef ArticlesState = LearningPagedState<Article>;

abstract class ArticlesEvent {
  const ArticlesEvent();
}

/// Fetches the first page for the current search; also used by Try Again.
class LoadArticles extends ArticlesEvent {
  const LoadArticles();
}

/// Starts over from page 1 with [term]. Debounce it in the UI.
class SearchArticles extends ArticlesEvent {
  const SearchArticles(this.term);

  final String term;
}

/// Fetches the next page. Ignored while one is loading or after the last.
class LoadMoreArticles extends ArticlesEvent {
  const LoadMoreArticles();
}

/// A list of articles - one category's, or all of them - paged and searched
/// on the server.
class ArticlesBloc extends Bloc<ArticlesEvent, ArticlesState> {
  ArticlesBloc(this._getArticles, {required this.scope, this.pageSize = 10})
    : super(const ArticlesState()) {
    on<LoadArticles>((event, emit) => _loadFirstPage(emit));
    on<SearchArticles>(_onSearch);
    on<LoadMoreArticles>(_onLoadMore);
  }

  final GetArticles _getArticles;
  final ArticleListScope scope;
  final int pageSize;

  String _searchTerm = '';

  /// Bumped for every first-page load, so a slow response for an earlier
  /// search cannot overwrite a newer one.
  int _generation = 0;

  Future<void> _onSearch(SearchArticles event, Emitter<ArticlesState> emit) {
    final term = event.term.trim();
    if (term == _searchTerm) return Future.value();
    _searchTerm = term;
    return _loadFirstPage(emit);
  }

  Future<void> _loadFirstPage(Emitter<ArticlesState> emit) async {
    final generation = ++_generation;
    final term = _searchTerm;
    emit(ArticlesState(searchTerm: term));
    final result = await _getArticles(
      scope,
      page: 1,
      limit: pageSize,
      searchTerm: term,
    );
    if (generation != _generation) return;
    result.fold(
      (failure) => emit(
        ArticlesState(
          status: LearningLoadStatus.failure,
          searchTerm: term,
          failure: failure,
        ),
      ),
      (page) => emit(
        ArticlesState(
          status: LearningLoadStatus.success,
          items: page.articles,
          page: page.meta.page,
          hasMore: page.meta.hasMore,
          searchTerm: term,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreArticles event,
    Emitter<ArticlesState> emit,
  ) async {
    if (!state.canLoadMore) return;
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true, clearLoadMoreFailure: true));
    final result = await _getArticles(
      scope,
      page: state.page + 1,
      limit: pageSize,
      searchTerm: _searchTerm,
    );
    if (generation != _generation) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingMore: false, loadMoreFailure: failure)),
      (page) => emit(
        state.copyWith(
          isLoadingMore: false,
          items: appendPage(state.items, page.articles, (a) => a.id),
          page: page.meta.page,
          hasMore: page.meta.hasMore,
        ),
      ),
    );
  }
}
