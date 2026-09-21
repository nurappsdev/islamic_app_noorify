import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_read_record.dart';

enum HadithReadRecordsStatus { initial, loading, success, failure }

class HadithReadRecordsState {
  const HadithReadRecordsState({
    this.status = HadithReadRecordsStatus.initial,
    this.records = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final HadithReadRecordsStatus status;

  /// Every record loaded so far, across pages.
  final List<HadithReadRecord> records;

  /// The last page loaded (0 before the first).
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  /// Set when the first page failed.
  final Failure? failure;

  /// Set when a later page failed — the loaded list stays on screen.
  final Failure? loadMoreFailure;

  bool get isLoading =>
      status == HadithReadRecordsStatus.initial ||
      status == HadithReadRecordsStatus.loading;

  HadithReadRecordsState copyWith({
    List<HadithReadRecord>? records,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) => HadithReadRecordsState(
    status: status,
    records: records ?? this.records,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    failure: failure,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : (loadMoreFailure ?? this.loadMoreFailure),
  );
}
