import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';

enum HadithDashboardStatus { initial, loading, success, failure }

class HadithDashboardState {
  const HadithDashboardState({
    this.period = HadithHistoryPeriod.daily,
    this.month,
    this.status = HadithDashboardStatus.initial,
    this.from,
    this.to,
    this.history,
    this.failure,
  });

  final HadithHistoryPeriod period;

  /// The first day of the calendar month picked with the month button; null
  /// while a rolling [period] is shown.
  final DateTime? month;
  final HadithDashboardStatus status;

  /// The (inclusive) date range [history] was requested for.
  final DateTime? from;
  final DateTime? to;
  final HadithReadingHistory? history;
  final Failure? failure;

  bool get isLoading =>
      status == HadithDashboardStatus.initial ||
      status == HadithDashboardStatus.loading;
}
