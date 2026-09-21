import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_comparison.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';

enum HadithComparisonStatus { initial, loading, success, failure }

class HadithComparisonState {
  const HadithComparisonState({
    this.status = HadithComparisonStatus.initial,
    this.period,
    this.month,
    this.competitor,
    this.failure,
  });

  final HadithComparisonStatus status;

  /// The period (and month, if one was picked) [competitor] was loaded for, so
  /// a stale result is never drawn under other dates.
  final HadithHistoryPeriod? period;
  final DateTime? month;

  /// Null while loading, on failure, or when nobody else was returned.
  final HadithCompetitor? competitor;
  final Failure? failure;

  bool get isLoading => status == HadithComparisonStatus.loading;
}
