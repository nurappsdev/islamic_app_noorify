import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/amol_tracking/domain/usecases/get_amol_daily.dart';

import 'amol_daily_event.dart';
import 'amol_daily_state.dart';

export 'amol_daily_event.dart';
export 'amol_daily_state.dart';

class AmolDailyBloc extends Bloc<AmolDailyEvent, AmolDailyState> {
  AmolDailyBloc(this._getAmolDaily) : super(const AmolDailyState.initial()) {
    on<LoadAmolDaily>(_onLoad);
  }

  final GetAmolDaily _getAmolDaily;

  Future<void> _onLoad(
    LoadAmolDaily event,
    Emitter<AmolDailyState> emit,
  ) async {
    emit(const AmolDailyState.loading());
    final result = await _getAmolDaily(date: event.date);
    result.fold(
      (failure) => emit(AmolDailyState.failure(failure)),
      (dashboard) => emit(AmolDailyState.success(dashboard)),
    );
  }
}
