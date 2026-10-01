import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/get_quiz_dashboard.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/get_quiz_dashboard_comparison.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/bloc/quiz_dashboard_paging.dart';

import 'quiz_dashboard_event.dart';
import 'quiz_dashboard_state.dart';

export 'quiz_dashboard_event.dart';
export 'quiz_dashboard_state.dart';

/// The dates a dashboard period covers around [date], as the date selector
/// labels them: the day, its Monday-Sunday week, or its calendar month.
({DateTime from, DateTime to}) quizDashboardRange(
  QuizDashboardPeriod period,
  DateTime date,
) {
  final day = DateTime(date.year, date.month, date.day);
  switch (period) {
    case QuizDashboardPeriod.daily:
      return (from: day, to: day);
    case QuizDashboardPeriod.weekly:
      final monday = day.subtract(Duration(days: day.weekday - 1));
      return (from: monday, to: monday.add(const Duration(days: 6)));
    case QuizDashboardPeriod.monthly:
      return (
        from: DateTime(day.year, day.month),
        to: DateTime(day.year, day.month + 1, 0),
      );
  }
}

class QuizDashboardBloc extends Bloc<QuizDashboardEvent, QuizDashboardState> {
  QuizDashboardBloc({required this._getDashboard, required this._getComparison})
    : super(QuizDashboardState()) {
    on<LoadQuizDashboard>((event, emit) => _load(emit));

    on<SelectPeriod>((event, emit) async {
      if (state.selectedPeriod == event.period) return;
      emit(state.copyWith(selectedPeriod: event.period));
      await _load(emit);
    });

    on<DismissCompetitor>((event, emit) {
      if (state.showCompetitor) emit(state.copyWith(showCompetitor: false));
    });

    on<GoToPreviousDate>((event, emit) async {
      emit(state.copyWith(selectedDate: _shiftDate(state.selectedDate, -1)));
      await _load(emit);
    });

    on<GoToNextDate>((event, emit) async {
      emit(state.copyWith(selectedDate: _shiftDate(state.selectedDate, 1)));
      await _load(emit);
    });
  }

  final GetQuizDashboard _getDashboard;
  final GetQuizDashboardComparison _getComparison;

  /// Bumped per load, so a slow response for dates the user has already left
  /// cannot overwrite the newer one.
  int _generation = 0;

  /// The request for the selected period and dates. One page is sized to hold
  /// the whole range; more pages are still followed if the server sends them.
  QuizDashboardFilter get filter {
    final range = quizDashboardRange(state.period, state.selectedDate);
    final dayCount = range.to.difference(range.from).inDays + 1;
    return QuizDashboardFilter(
      period: state.period,
      from: range.from,
      to: range.to,
      limit: dayCount.clamp(1, 100),
    );
  }

  Future<void> _load(Emitter<QuizDashboardState> emit) async {
    final generation = ++_generation;
    final filter = this.filter;
    emit(
      state.withData(
        dashboardStatus: QuizDashboardLoadStatus.loading,
        comparisonStatus: QuizDashboardLoadStatus.loading,
      ),
    );

    final dashboardFuture = loadAllDashboardPages(_getDashboard.call, filter);
    final comparisonFuture = loadAllComparisonPages(
      _getComparison.call,
      filter,
    );
    final dashboard = await dashboardFuture;
    final comparison = await comparisonFuture;
    if (generation != _generation || emit.isDone) return;

    emit(
      state.withData(
        dashboardStatus: dashboard.isRight()
            ? QuizDashboardLoadStatus.success
            : QuizDashboardLoadStatus.failure,
        dashboard: dashboard.fold((_) => null, (data) => data),
        dashboardFailure: dashboard.fold((failure) => failure, (_) => null),
        comparisonStatus: comparison.isRight()
            ? QuizDashboardLoadStatus.success
            : QuizDashboardLoadStatus.failure,
        comparison: comparison.fold((_) => null, (data) => data),
        comparisonFailure: comparison.fold((failure) => failure, (_) => null),
      ),
    );
  }

  DateTime _shiftDate(DateTime date, int direction) {
    switch (state.selectedPeriod) {
      case 1: // Weekly
        return date.add(Duration(days: 7 * direction));
      case 2: // Monthly
        // Clamped, so 31 January steps to February rather than March.
        final lastDay = DateTime(date.year, date.month + direction + 1, 0).day;
        return DateTime(
          date.year,
          date.month + direction,
          date.day > lastDay ? lastDay : date.day,
        );
      default: // Daily
        return date.add(Duration(days: direction));
    }
  }
}
