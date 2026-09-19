import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_sub_category.dart';

enum HadithSubCategoryStatus { initial, loading, success, failure }

class HadithSubCategoryState {
  const HadithSubCategoryState({
    this.status = HadithSubCategoryStatus.initial,
    this.subCategories = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final HadithSubCategoryStatus status;

  /// Every sub-category loaded so far, across pages.
  final List<HadithSubCategory> subCategories;

  /// The last page loaded (0 before the first).
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  /// Set when the first page failed.
  final Failure? failure;

  /// Set when a later page failed — the loaded list stays on screen.
  final Failure? loadMoreFailure;

  bool get isLoading =>
      status == HadithSubCategoryStatus.initial ||
      status == HadithSubCategoryStatus.loading;

  HadithSubCategoryState copyWith({
    List<HadithSubCategory>? subCategories,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) => HadithSubCategoryState(
    status: status,
    subCategories: subCategories ?? this.subCategories,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    failure: failure,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : (loadMoreFailure ?? this.loadMoreFailure),
  );
}
