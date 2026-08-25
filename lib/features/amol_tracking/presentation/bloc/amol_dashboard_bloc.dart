import 'package:bloc/bloc.dart';

import 'amol_dashboard_event.dart';
import 'amol_dashboard_state.dart';

export 'amol_dashboard_event.dart';
export 'amol_dashboard_state.dart';

class AmolDashboardBloc extends Bloc<AmolDashboardEvent, AmolDashboardState> {
  AmolDashboardBloc({DateTime Function()? now})
    : super(
        AmolDashboardState(selectedPeriod: 0, date: (now ?? DateTime.now)()),
      ) {
    on<SelectPeriod>((event, emit) {
      if (state.selectedPeriod != event.period) {
        emit(state.copyWith(selectedPeriod: event.period));
      }
    });

    on<ShiftDate>((event, emit) {
      emit(state.copyWith(date: state.date.add(event.step * event.direction)));
    });
  }
}
