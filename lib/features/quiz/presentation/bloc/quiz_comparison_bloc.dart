import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/bloc/quiz_dashboard_paging.dart';

enum QuizComparisonStatus { loading, success, failure }

class QuizComparisonState {
  const QuizComparisonState({
    this.status = QuizComparisonStatus.loading,
    this.comparison,
    this.failure,
  });

  final QuizComparisonStatus status;
  final QuizComparison? comparison;
  final Failure? failure;
}

abstract class QuizComparisonEvent {
  const QuizComparisonEvent();
}

/// Fetches the comparison; also used by Try Again.
class LoadQuizComparison extends QuizComparisonEvent {
  const LoadQuizComparison();
}

/// The user next to the leaderboard leader over the last [days] days,
/// as one comparison endpoint returns it.
class QuizComparisonBloc
    extends Bloc<QuizComparisonEvent, QuizComparisonState> {
  QuizComparisonBloc(
    this._load, {
    this.period = QuizDashboardPeriod.weekly,
    this.days = 7,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const QuizComparisonState()) {
    on<LoadQuizComparison>((event, emit) async {
      final generation = ++_generation;
      emit(const QuizComparisonState());
      final result = await loadAllComparisonPages(_load, filter);
      if (generation != _generation || emit.isDone) return;
      result.fold(
        (failure) => emit(
          QuizComparisonState(
            status: QuizComparisonStatus.failure,
            failure: failure,
          ),
        ),
        (comparison) => emit(
          QuizComparisonState(
            status: QuizComparisonStatus.success,
            comparison: comparison,
          ),
        ),
      );
    });
  }

  final QuizPageLoader<QuizComparison> _load;
  final QuizDashboardPeriod period;
  final int days;
  final DateTime Function() _clock;
  int _generation = 0;

  /// The last [days] local days, ending today.
  QuizComparisonFilter get filter {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    return QuizComparisonFilter(
      period: period,
      from: today.subtract(Duration(days: days - 1)),
      to: today,
      limit: days.clamp(1, 100),
    );
  }
}
