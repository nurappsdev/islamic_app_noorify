import 'package:bloc/bloc.dart';

import 'quiz_dashboard_state.dart';

export 'quiz_dashboard_state.dart';

class QuizDashboardCubit extends Cubit<QuizDashboardState> {
  QuizDashboardCubit() : super(QuizDashboardState());

  void selectPeriod(int period) {
    if (state.selectedPeriod != period) {
      emit(state.copyWith(selectedPeriod: period));
    }
  }

  void dismissCompetitor() {
    if (state.showCompetitor) emit(state.copyWith(showCompetitor: false));
  }

  void goToPreviousDate() {
    emit(state.copyWith(selectedDate: _shiftDate(state.selectedDate, -1)));
  }

  void goToNextDate() {
    emit(state.copyWith(selectedDate: _shiftDate(state.selectedDate, 1)));
  }

  DateTime _shiftDate(DateTime date, int direction) {
    switch (state.selectedPeriod) {
      case 1: // Weekly
        return date.add(Duration(days: 7 * direction));
      case 2: // Monthly
        return DateTime(date.year, date.month + direction, date.day);
      default: // Daily
        return date.add(Duration(days: direction));
    }
  }
}
