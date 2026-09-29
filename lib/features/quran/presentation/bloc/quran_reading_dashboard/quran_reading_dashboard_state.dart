import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_dashboard.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_history.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/dashboard/quran_period_dropdown.dart';

enum QuranReadingDashboardStatus {
  initial,
  loading,
  loaded,
  failure,
  signedOut,
}

class QuranReadingDashboardState {
  const QuranReadingDashboardState({
    this.status = QuranReadingDashboardStatus.initial,
    this.period = QuranDashboardPeriod.weekly,
    this.month,
    this.dashboard,
    this.history,
    this.comparison,
    this.failureMessage,
  });

  final QuranReadingDashboardStatus status;
  final QuranDashboardPeriod period;

  /// The picked calendar month (its first day) for [period] monthly; null
  /// for the rolling window.
  final DateTime? month;
  final QuranReadingDashboard? dashboard;

  /// The chart's window ([period] / [month]).
  final QuranReadingHistory? history;
  final QuranReadingComparison? comparison;

  /// Set with [QuranReadingDashboardStatus.failure]; safe to show.
  final String? failureMessage;

  bool get isLoading => status == QuranReadingDashboardStatus.loading;

  QuranReadingDashboardState copyWith({
    QuranReadingDashboardStatus? status,
    QuranDashboardPeriod? period,
    DateTime? Function()? month,
    QuranReadingDashboard? dashboard,
    QuranReadingHistory? Function()? history,
    QuranReadingComparison? Function()? comparison,
    String? Function()? failureMessage,
  }) => QuranReadingDashboardState(
    status: status ?? this.status,
    period: period ?? this.period,
    month: month == null ? this.month : month(),
    dashboard: dashboard ?? this.dashboard,
    history: history == null ? this.history : history(),
    comparison: comparison == null ? this.comparison : comparison(),
    failureMessage: failureMessage == null
        ? this.failureMessage
        : failureMessage(),
  );
}
