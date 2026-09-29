import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_reading_comparison.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_reading_history.dart';

enum HadithComparisonStatus { initial, loading, success, failure }

class HadithComparisonState {
  const HadithComparisonState({
    this.status = HadithComparisonStatus.initial,
    this.period,
    this.month,
    this.competitor,
    this.myName = '',
    this.failure,
  });

  final HadithComparisonStatus status;

  /// The period (and month, if one was picked) [competitor] was loaded for, so
  /// a stale result is never drawn under other dates.
  final HadithHistoryPeriod? period;
  final DateTime? month;

  /// Null while loading, on failure, or when nobody else was returned.
  final HadithCompetitor? competitor;

  /// The user's own name from the same response, for their initials.
  final String myName;
  final Failure? failure;

  bool get isLoading => status == HadithComparisonStatus.loading;
}
