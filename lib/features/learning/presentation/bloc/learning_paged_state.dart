import 'package:islami_app_noorify/core/errors/failures.dart';

enum LearningLoadStatus { loading, success, failure }

/// A list the server pages: what has loaded so far, and how the next page is
/// doing.
class LearningPagedState<T> {
  const LearningPagedState({
    this.status = LearningLoadStatus.loading,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.searchTerm = '',
    this.failure,
    this.loadMoreFailure,
  });

  final LearningLoadStatus status;

  /// Every item loaded so far, across pages.
  final List<T> items;

  /// The last page loaded (0 before the first).
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  /// The search the items match; empty for none.
  final String searchTerm;

  /// Set when the first page failed.
  final Failure? failure;

  /// Set when a later page failed; the loaded items stay on screen.
  final Failure? loadMoreFailure;

  bool get isLoading => status == LearningLoadStatus.loading;

  /// Whether scrolling to the end should fetch another page.
  bool get canLoadMore =>
      status == LearningLoadStatus.success && hasMore && !isLoadingMore;

  LearningPagedState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) => LearningPagedState<T>(
    status: status,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    searchTerm: searchTerm,
    failure: failure,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : (loadMoreFailure ?? this.loadMoreFailure),
  );
}

/// [current] followed by the items of [next] it does not already hold, so a
/// list that shifted between pages shows nothing twice.
List<T> appendPage<T>(
  List<T> current,
  List<T> next,
  String Function(T item) idOf,
) {
  final known = current.map(idOf).toSet();
  return [...current, ...next.where((item) => known.add(idOf(item)))];
}
