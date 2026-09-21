import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_plan.dart';

enum HadithPlansStatus { initial, loading, success, failure }

class HadithPlansState {
  const HadithPlansState({
    this.status = HadithPlansStatus.initial,
    this.plans = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final HadithPlansStatus status;

  /// Every plan loaded so far, across pages.
  final List<HadithPlan> plans;

  /// The last page loaded (0 before the first).
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  /// Set when the first page failed.
  final Failure? failure;

  /// Set when a later page failed — the loaded list stays on screen.
  final Failure? loadMoreFailure;

  bool get isLoading =>
      status == HadithPlansStatus.initial ||
      status == HadithPlansStatus.loading;

  HadithPlansState copyWith({
    List<HadithPlan>? plans,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) => HadithPlansState(
    status: status,
    plans: plans ?? this.plans,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    failure: failure,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : (loadMoreFailure ?? this.loadMoreFailure),
  );
}
