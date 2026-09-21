import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';

abstract class HadithDashboardEvent {
  const HadithDashboardEvent();
}

/// Loads (or reloads) the dashboard for [period]; also the retry after a
/// failure.
///
/// With [month] (any date in it) the dashboard shows that calendar month
/// instead of the period's rolling dates, grouped like a monthly period.
class LoadHadithDashboard extends HadithDashboardEvent {
  const LoadHadithDashboard(this.period, {this.month});

  final HadithHistoryPeriod period;
  final DateTime? month;
}
