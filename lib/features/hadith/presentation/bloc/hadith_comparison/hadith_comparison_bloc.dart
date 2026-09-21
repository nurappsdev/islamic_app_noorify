import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_reading_comparison.dart';

import 'hadith_comparison_event.dart';
import 'hadith_comparison_state.dart';

export 'hadith_comparison_event.dart';
export 'hadith_comparison_state.dart';

class HadithComparisonBloc
    extends Bloc<HadithComparisonEvent, HadithComparisonState> {
  HadithComparisonBloc(this._getComparison)
    : super(const HadithComparisonState()) {
    on<LoadHadithComparison>(_onLoad);
  }

  final GetHadithReadingComparison _getComparison;

  /// Bumped per request so a slow response for a period the user has already
  /// switched away from can't overwrite the newer one.
  int _generation = 0;

  Future<void> _onLoad(
    LoadHadithComparison event,
    Emitter<HadithComparisonState> emit,
  ) async {
    final generation = ++_generation;
    final month = event.month;
    final range = month == null
        ? hadithHistoryRange(event.period)
        : hadithMonthRange(month);
    emit(
      HadithComparisonState(
        status: HadithComparisonStatus.loading,
        period: event.period,
        month: month,
      ),
    );
    final result = await _getComparison(from: range.from, to: range.to);
    if (generation != _generation || emit.isDone) return;
    result.fold(
      (failure) => emit(
        HadithComparisonState(
          status: HadithComparisonStatus.failure,
          period: event.period,
          month: month,
          failure: failure,
        ),
      ),
      (comparison) => emit(
        HadithComparisonState(
          status: HadithComparisonStatus.success,
          period: event.period,
          month: month,
          competitor: comparison.competitor,
          myName: comparison.myName,
        ),
      ),
    );
  }
}
