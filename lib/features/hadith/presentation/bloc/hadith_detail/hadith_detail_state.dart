import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail.dart';

enum HadithDetailStatus { initial, loading, success, failure }

class HadithDetailState {
  const HadithDetailState({
    this.status = HadithDetailStatus.initial,
    this.hadiths = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final HadithDetailStatus status;

  /// Every hadith loaded so far, across pages.
  final List<HadithDetail> hadiths;

  /// The last page loaded (0 before the first).
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  /// Set when the first page failed.
  final Failure? failure;

  /// Set when a later page failed — the loaded list stays on screen.
  final Failure? loadMoreFailure;

  bool get isLoading =>
      status == HadithDetailStatus.initial ||
      status == HadithDetailStatus.loading;

  HadithDetailState copyWith({
    List<HadithDetail>? hadiths,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) => HadithDetailState(
    status: status,
    hadiths: hadiths ?? this.hadiths,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    failure: failure,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : (loadMoreFailure ?? this.loadMoreFailure),
  );
}
