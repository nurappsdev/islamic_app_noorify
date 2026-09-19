import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category.dart';

enum HadithCategoryStatus { initial, loading, success, failure }

class HadithCategoryState {
  const HadithCategoryState({
    this.status = HadithCategoryStatus.initial,
    this.categories = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final HadithCategoryStatus status;

  /// Every category loaded so far, across pages.
  final List<HadithCategory> categories;

  /// The last page loaded (0 before the first).
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  /// Set when the first page failed.
  final Failure? failure;

  /// Set when a later page failed — the loaded list stays on screen.
  final Failure? loadMoreFailure;

  bool get isLoading =>
      status == HadithCategoryStatus.initial ||
      status == HadithCategoryStatus.loading;

  HadithCategoryState copyWith({
    HadithCategoryStatus? status,
    List<HadithCategory>? categories,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? failure,
    Failure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) => HadithCategoryState(
    status: status ?? this.status,
    categories: categories ?? this.categories,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    failure: failure ?? this.failure,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : (loadMoreFailure ?? this.loadMoreFailure),
  );
}
