import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';

abstract class HadithComparisonEvent {
  const HadithComparisonEvent();
}

/// Loads the comparison for [period], or for the calendar [month] when given —
/// the same dates the dashboard shows. Sent when the competitor toggle is
/// switched on, and again when the period or month changes while it is on.
class LoadHadithComparison extends HadithComparisonEvent {
  const LoadHadithComparison(this.period, {this.month});

  final HadithHistoryPeriod period;
  final DateTime? month;
}
