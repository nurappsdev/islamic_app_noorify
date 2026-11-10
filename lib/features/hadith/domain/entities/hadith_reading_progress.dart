/// Reading progress of one hadith category
/// (`GET /hadiths/reading/progress/categories`).
class HadithCategoryProgress {
  const HadithCategoryProgress({
    required this.id,
    required this.bookId,
    required this.totalHadiths,
    required this.readHadiths,
    required this.percentage,
  });

  /// The category's id — what a category is matched by (names vary by
  /// language).
  final String id;
  final String bookId;
  final int totalHadiths;
  final int readHadiths;

  /// As the backend reports it, clamped to `0..100`.
  final double percentage;

  /// [percentage] as a `0..1` value for a progress indicator.
  double get fraction => percentage / 100;
}

/// The overall summary of `GET /hadiths/reading/progress/categories`.
class HadithReadingSummary {
  const HadithReadingSummary({
    required this.totalHadiths,
    required this.readHadiths,
    required this.percentage,
    required this.completedGroups,
  });

  final int totalHadiths;
  final int readHadiths;

  /// As the backend reports it, clamped to `0..100`.
  final double percentage;
  final int completedGroups;
}

/// The whole progress response: the overall [summary] and one entry per
/// category, indexed by category id.
class HadithReadingProgress {
  const HadithReadingProgress({required this.summary, required this.byId});

  final HadithReadingSummary summary;
  final Map<String, HadithCategoryProgress> byId;

  HadithCategoryProgress? forCategory(String categoryId) => byId[categoryId];
}
