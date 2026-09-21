import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';

/// The other reader the user is compared with
/// (`GET /hadiths/reading/history/compare`).
class HadithCompetitor {
  const HadithCompetitor({
    required this.name,
    required this.avatarUrl,
    required this.rank,
    required this.totalPoints,
    required this.days,
  });

  final String name;
  final String avatarUrl;
  final int rank;
  final double totalPoints;

  /// Their reading day by day over the requested range.
  final List<HadithReadingDay> days;

  /// Up to two capital letters of [name] ("Yousuf Ahmed" -> "YA").
  String get initials {
    final letters = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.substring(0, 1).toUpperCase())
        .take(2)
        .join();
    return letters;
  }
}

class HadithReadingComparison {
  const HadithReadingComparison({
    required this.comparedWith,
    required this.competitor,
  });

  /// Who the user is compared with, e.g. `first_place`.
  final String comparedWith;

  /// Null when the response has no reader other than the user.
  final HadithCompetitor? competitor;
}
