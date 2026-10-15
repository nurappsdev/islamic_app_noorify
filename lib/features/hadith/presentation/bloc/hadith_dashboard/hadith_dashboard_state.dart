import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_reading_history.dart';

enum HadithDashboardStatus { initial, loading, success, failure }

class HadithDashboardState {
  const HadithDashboardState({
    this.period = HadithHistoryPeriod.daily,
    this.month,
    this.endDate,
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

  /// The requested end of a daily/weekly window; null while it's today (the
  /// default, before the back/forward arrows have been used).
  final DateTime? endDate;
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
