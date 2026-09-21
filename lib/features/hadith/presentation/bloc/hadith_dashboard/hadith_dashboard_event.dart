import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';

abstract class HadithDashboardEvent {
  const HadithDashboardEvent();
}

/// Loads (or reloads) the dashboard for [period]; also the retry after a
/// failure.
class LoadHadithDashboard extends HadithDashboardEvent {
  const LoadHadithDashboard(this.period);

  final HadithHistoryPeriod period;
}
