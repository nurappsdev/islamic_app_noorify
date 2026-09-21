import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_reading_history.dart';

import 'hadith_dashboard_event.dart';
import 'hadith_dashboard_state.dart';

export 'hadith_dashboard_event.dart';
export 'hadith_dashboard_state.dart';

class HadithDashboardBloc
    extends Bloc<HadithDashboardEvent, HadithDashboardState> {
  HadithDashboardBloc(this._getHistory) : super(const HadithDashboardState()) {
    on<LoadHadithDashboard>(_onLoad);
  }

  final GetHadithReadingHistory _getHistory;

  /// Bumped per request so a slow response for a period the user has already
  /// switched away from can't overwrite the newer one.
  int _generation = 0;

  Future<void> _onLoad(
    LoadHadithDashboard event,
    Emitter<HadithDashboardState> emit,
  ) async {
    final generation = ++_generation;
    final range = hadithHistoryRange(event.period);
    // Cleared while loading, so a different period's data is never shown
    // under the newly selected filter.
    emit(
      HadithDashboardState(
        period: event.period,
        status: HadithDashboardStatus.loading,
        from: range.from,
        to: range.to,
      ),
    );
    final result = await _getHistory(from: range.from, to: range.to);
    if (generation != _generation || emit.isDone) return;
    result.fold(
      (failure) => emit(
        HadithDashboardState(
          period: event.period,
          status: HadithDashboardStatus.failure,
          from: range.from,
          to: range.to,
          failure: failure,
        ),
      ),
      (history) => emit(
        HadithDashboardState(
          period: event.period,
          status: HadithDashboardStatus.success,
          from: range.from,
          to: range.to,
          history: history,
        ),
      ),
    );
  }
}
