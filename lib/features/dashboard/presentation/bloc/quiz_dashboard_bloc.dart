import 'package:bloc/bloc.dart';

import 'quiz_dashboard_event.dart';
import 'quiz_dashboard_state.dart';

export 'quiz_dashboard_event.dart';
export 'quiz_dashboard_state.dart';

class QuizDashboardBloc extends Bloc<QuizDashboardEvent, QuizDashboardState> {
  QuizDashboardBloc() : super(QuizDashboardState()) {
    on<SelectPeriod>((event, emit) {
      if (state.selectedPeriod != event.period) {
        emit(state.copyWith(selectedPeriod: event.period));
      }
    });

    on<DismissCompetitor>((event, emit) {
      if (state.showCompetitor) emit(state.copyWith(showCompetitor: false));
    });

    on<GoToPreviousDate>((event, emit) {
      emit(state.copyWith(selectedDate: _shiftDate(state.selectedDate, -1)));
    });

    on<GoToNextDate>((event, emit) {
      emit(state.copyWith(selectedDate: _shiftDate(state.selectedDate, 1)));
    });
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
