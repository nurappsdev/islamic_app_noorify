import 'package:bloc/bloc.dart';

import 'quiz_dashboard_state.dart';

export 'quiz_dashboard_state.dart';

class QuizDashboardCubit extends Cubit<QuizDashboardState> {
  QuizDashboardCubit() : super(const QuizDashboardState());

  void selectPeriod(int period) {
    if (state.selectedPeriod != period) {
      emit(state.copyWith(selectedPeriod: period));
    }
  }

  void dismissCompetitor() {
    if (state.showCompetitor) emit(state.copyWith(showCompetitor: false));
  }
}
