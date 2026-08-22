import 'package:bloc/bloc.dart';

import 'amol_dashboard_state.dart';

export 'amol_dashboard_state.dart';

class AmolDashboardCubit extends Cubit<AmolDashboardState> {
  AmolDashboardCubit({DateTime Function()? now})
    : super(
        AmolDashboardState(selectedPeriod: 0, date: (now ?? DateTime.now)()),
      );

  void selectPeriod(int period) {
    if (state.selectedPeriod != period) {
      emit(state.copyWith(selectedPeriod: period));
    }
  }

  void shiftDate(Duration step, int direction) {
    emit(state.copyWith(date: state.date.add(step * direction)));
  }
}
