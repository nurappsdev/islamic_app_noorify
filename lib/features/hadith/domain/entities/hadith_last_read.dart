/// The hadith the user read most recently
/// (`GET /hadiths/reading/last-read`).
class HadithLastRead {
  const HadithLastRead({
    required this.hadithId,
    required this.hadithNumber,
    required this.sourceBangla,
    required this.sourceEnglish,
    required this.bookId,
    required this.subCategoryId,
    required this.subCategoryNameBangla,
    required this.subCategoryNameEnglish,
  });

  final String hadithId;
  final int hadithNumber;
  final String sourceBangla;
  final String sourceEnglish;
  final String bookId;

  /// The sub-category (chapter) the hadith belongs to — what the detail
  /// screen lists hadiths by.
  final String subCategoryId;
  final String subCategoryNameBangla;
  final String subCategoryNameEnglish;

  String source({required bool bangla}) =>
      _localized(bangla, sourceBangla, sourceEnglish);

  String subCategoryName({required bool bangla}) =>
      _localized(bangla, subCategoryNameBangla, subCategoryNameEnglish);

  static String _localized(bool bangla, String bn, String en) {
    final preferred = bangla ? bn : en;
    return preferred.isEmpty ? (bangla ? en : bn) : preferred;
  }
}
