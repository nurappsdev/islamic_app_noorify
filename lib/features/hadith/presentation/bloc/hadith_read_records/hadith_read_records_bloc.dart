import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_read_records.dart';

import 'hadith_read_records_event.dart';
import 'hadith_read_records_state.dart';

export 'hadith_read_records_event.dart';
export 'hadith_read_records_state.dart';

/// The user's reading history, [pageSize] records per page. The dashboard
/// shows just the first page of 3; the full list pages through with 10.
class HadithReadRecordsBloc
    extends Bloc<HadithReadRecordsEvent, HadithReadRecordsState> {
  HadithReadRecordsBloc(this._getRecords, {required this.pageSize})
    : super(const HadithReadRecordsState()) {
    on<LoadHadithReadRecords>(_onLoad);
    on<LoadMoreHadithReadRecords>(_onLoadMore);
  }

  final GetHadithReadRecords _getRecords;
  final int pageSize;

  /// Bumped for every fresh first-page load so a slow, superseded response
  /// can't overwrite a newer one.
  int _generation = 0;

  Future<void> _onLoad(
    LoadHadithReadRecords event,
    Emitter<HadithReadRecordsState> emit,
  ) async {
    final generation = ++_generation;
    emit(const HadithReadRecordsState(status: HadithReadRecordsStatus.loading));
    final result = await _getRecords(page: 1, limit: pageSize);
    if (generation != _generation || emit.isDone) return;
    result.fold(
      (failure) => emit(
        HadithReadRecordsState(
          status: HadithReadRecordsStatus.failure,
          failure: failure,
        ),
      ),
      (page) => emit(
        HadithReadRecordsState(
          status: HadithReadRecordsStatus.success,
          records: page.records,
          page: page.page,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreHadithReadRecords event,
    Emitter<HadithReadRecordsState> emit,
  ) async {
    if (state.status != HadithReadRecordsStatus.success ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true, clearLoadMoreFailure: true));
    final result = await _getRecords(page: state.page + 1, limit: pageSize);
    if (generation != _generation || emit.isDone) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingMore: false, loadMoreFailure: failure)),
      (page) => emit(
        state.copyWith(
          isLoadingMore: false,
          records: [...state.records, ...page.records],
          page: page.page,
          hasMore: page.hasMore,
        ),
      ),
    );
  }
}
