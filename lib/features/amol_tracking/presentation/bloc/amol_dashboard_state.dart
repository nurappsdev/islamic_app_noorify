import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_graph.dart';

enum AmolDashboardStatus { initial, loading, success, failure }

class AmolDashboardState {
  const AmolDashboardState({
    required this.selectedPeriod,
    required this.date,
    required this.today,
    this.status = AmolDashboardStatus.initial,
    this.graph,
    this.failure,
    this.rangeStart,
  });

  final int selectedPeriod;

  /// The end of the requested window (for daily, the single day itself).
  final DateTime date;

  /// Fixed at bloc creation (real "now", or the test-injected clock) —
  /// unlike [date], this never moves as the user navigates, so it anchors
  /// things like the month-picker's "last 12 months" list.
  final DateTime today;
  final AmolDashboardStatus status;

  /// The last successfully loaded graph. Kept across a later `loading`/
  /// `failure` so the chart doesn't blank out while refetching.
  final AmolAnalyticsGraph? graph;
  final Failure? failure;

  /// Explicit start of the requested window, set only when the user picked
  /// a specific past calendar month from [SelectMonth]'s dropdown — `null`
  /// means "derive it from [date] and the period's sliding-window length"
  /// (the normal daily/weekly/monthly navigation case).
  final DateTime? rangeStart;

  bool get isLoading => status == AmolDashboardStatus.loading;
  String? get errorMessage => failure?.message;

  AmolDashboardState copyWith({
    int? selectedPeriod,
    DateTime? date,
    AmolDashboardStatus? status,
    AmolAnalyticsGraph? graph,
    Failure? failure,
    bool clearFailure = false,
    DateTime? rangeStart,
    bool clearRangeStart = false,
  }) {
    return AmolDashboardState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      date: date ?? this.date,
      today: today,
      status: status ?? this.status,
      graph: graph ?? this.graph,
      failure: clearFailure ? null : (failure ?? this.failure),
      rangeStart: clearRangeStart ? null : (rangeStart ?? this.rangeStart),
    );
  }
}
