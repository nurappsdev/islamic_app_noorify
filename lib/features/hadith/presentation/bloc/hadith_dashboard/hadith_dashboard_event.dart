import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_reading_history.dart';

abstract class HadithDashboardEvent {
  const HadithDashboardEvent();
}

/// Loads (or reloads) the dashboard for [period]; also the retry after a
/// failure.
///
/// With [month] (any date in it) the dashboard shows that calendar month
/// instead of the period's rolling dates, grouped like a monthly period.
///
/// With [endDate], a daily/weekly window ends on that date instead of today -
/// how the back/forward arrows step through earlier (or later, up to today)
/// windows without touching [month].
class LoadHadithDashboard extends HadithDashboardEvent {
  const LoadHadithDashboard(this.period, {this.month, this.endDate});

  final HadithHistoryPeriod period;
  final DateTime? month;
  final DateTime? endDate;
}
