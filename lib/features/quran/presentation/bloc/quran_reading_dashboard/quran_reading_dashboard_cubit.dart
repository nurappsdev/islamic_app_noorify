import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/quran/domain/repositories/quran_reading_repository.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/dashboard/quran_period_dropdown.dart';

import 'quran_reading_dashboard_state.dart';

export 'quran_reading_dashboard_state.dart';

/// Rolling window of the monthly chart when no calendar month is picked.
const kQuranMonthlyWindowDays = 30;

/// The Quran dashboard's data: `GET /quran/reading/dashboard`, plus the
/// reading history and comparison for the chart's period.
///
/// Reloads on its own after each tracked reading. Loads that overlap share
/// one run, and the repository caches responses, so calling [load] whenever
/// the tab is shown is cheap.
class QuranReadingDashboardCubit extends Cubit<QuranReadingDashboardState> {
  QuranReadingDashboardCubit(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const QuranReadingDashboardState()) {
    _tracked = _repository.onReadingTracked.listen((_) => load());
  }

  final QuranReadingRepository _repository;
  final DateTime Function() _now;
  late final StreamSubscription<void> _tracked;
  Future<void>? _loading;

  /// Loads (or refreshes) everything; data already shown stays on screen
  /// while it refreshes.
  Future<void> load() =>
      _loading ??= _load().whenComplete(() => _loading = null);

  /// Switches the chart to [period] (and, for monthly, the calendar [month]).
  Future<void> selectPeriod(QuranDashboardPeriod period, {DateTime? month}) {
    emit(
      state.copyWith(
        period: period,
        month: () => month,
        history: () => null,
        comparison: () => null,
      ),
    );
    // A load already running may be for the old period: chain another.
    final running = _loading;
    return running == null ? load() : running.then((_) => load());
  }

  Future<void> _load() async {
    if (!_repository.isSignedIn) {
      emit(
        state.copyWith(
          status: QuranReadingDashboardStatus.signedOut,
          failureMessage: () => null,
        ),
      );
      return;
    }
    if (state.dashboard == null) {
      emit(state.copyWith(status: QuranReadingDashboardStatus.loading));
    }

    final period = state.period;
    final month = state.month;
    final window = _windowFor(period, month);
    final dashboardRequest = _repository.getDashboard();
    final historyRequest = _repository.getReadingHistory(
      days: window.days,
      from: window.from,
      to: window.to,
    );
    final comparisonRequest = _repository.getReadingComparison(
      days: window.days,
      from: window.from,
      to: window.to,
    );
    final dashboard = await dashboardRequest;
    final history = await historyRequest;
    final comparison = await comparisonRequest;
    // The period changed meanwhile: its own load will fill it in.
    if (isClosed || state.period != period || state.month != month) return;

    dashboard.fold(
      (failure) => emit(
        state.dashboard == null
            ? state.copyWith(
                status: QuranReadingDashboardStatus.failure,
                failureMessage: () => failure.message,
              )
            // Keep what is on screen; a later refresh may succeed.
            : state.copyWith(status: QuranReadingDashboardStatus.loaded),
      ),
      (data) => emit(
        state.copyWith(
          status: QuranReadingDashboardStatus.loaded,
          dashboard: data,
          history: () => history.fold((_) => state.history, (h) => h),
          comparison: () => comparison.fold((_) => state.comparison, (c) => c),
          failureMessage: () => null,
        ),
      ),
    );
  }

  /// The history window for [period]: the last day, the last week, the
  /// last [kQuranMonthlyWindowDays] days, or the picked calendar [month]
  /// (up to today).
  ({int days, DateTime? from, DateTime? to}) _windowFor(
    QuranDashboardPeriod period,
    DateTime? month,
  ) {
    switch (period) {
      case QuranDashboardPeriod.daily:
        return (days: 1, from: null, to: null);
      case QuranDashboardPeriod.weekly:
        return (days: kQuranReadingHistoryDays, from: null, to: null);
      case QuranDashboardPeriod.monthly:
        if (month == null) {
          return (days: kQuranMonthlyWindowDays, from: null, to: null);
        }
        final now = _now();
        final today = DateTime(now.year, now.month, now.day);
        final first = DateTime(month.year, month.month);
        final last = DateTime(month.year, month.month + 1, 0);
        final to = last.isAfter(today) ? today : last;
        return (
          days: math.max(to.difference(first).inDays + 1, 1),
          from: first,
          to: to,
        );
    }
  }

  @override
  Future<void> close() {
    _tracked.cancel();
    return super.close();
  }
}
