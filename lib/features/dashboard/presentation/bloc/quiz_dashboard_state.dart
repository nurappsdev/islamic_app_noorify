import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_dashboard.dart';

enum QuizDashboardLoadStatus { initial, loading, success, failure }

class QuizDashboardState {
  QuizDashboardState({
    this.selectedPeriod = 0,
    this.showCompetitor = true,
    DateTime? selectedDate,
    this.dashboardStatus = QuizDashboardLoadStatus.initial,
    this.dashboard,
    this.dashboardFailure,
    this.comparisonStatus = QuizDashboardLoadStatus.initial,
    this.comparison,
    this.comparisonFailure,
  }) : selectedDate = selectedDate ?? DateTime.now();

  /// 0 daily, 1 weekly, 2 monthly - the tab order.
  final int selectedPeriod;
  final bool showCompetitor;
  final DateTime selectedDate;

  final QuizDashboardLoadStatus dashboardStatus;

  /// Every day of the range, all pages merged. Cleared while another range
  /// loads, so figures for other dates are never shown under these.
  final QuizDashboardData? dashboard;
  final Failure? dashboardFailure;

  final QuizDashboardLoadStatus comparisonStatus;
  final QuizComparison? comparison;
  final Failure? comparisonFailure;

  QuizDashboardPeriod get period =>
      QuizDashboardPeriod.values[selectedPeriod.clamp(0, 2)];

  QuizDashboardState copyWith({
    int? selectedPeriod,
    bool? showCompetitor,
    DateTime? selectedDate,
  }) {
    return QuizDashboardState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      showCompetitor: showCompetitor ?? this.showCompetitor,
      selectedDate: selectedDate ?? this.selectedDate,
      dashboardStatus: dashboardStatus,
      dashboard: dashboard,
      dashboardFailure: dashboardFailure,
      comparisonStatus: comparisonStatus,
      comparison: comparison,
      comparisonFailure: comparisonFailure,
    );
  }

  /// This state with the data parts replaced; any part not given is cleared.
  QuizDashboardState withData({
    required QuizDashboardLoadStatus dashboardStatus,
    QuizDashboardData? dashboard,
    Failure? dashboardFailure,
    required QuizDashboardLoadStatus comparisonStatus,
    QuizComparison? comparison,
    Failure? comparisonFailure,
  }) {
    return QuizDashboardState(
      selectedPeriod: selectedPeriod,
      showCompetitor: showCompetitor,
      selectedDate: selectedDate,
      dashboardStatus: dashboardStatus,
      dashboard: dashboard,
      dashboardFailure: dashboardFailure,
      comparisonStatus: comparisonStatus,
      comparison: comparison,
      comparisonFailure: comparisonFailure,
    );
  }
}
