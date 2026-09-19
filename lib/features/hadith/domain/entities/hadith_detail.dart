/// One hadith of a sub-category (`GET /hadiths?subCategoryId=...`).
class HadithDetail {
  const HadithDetail({
    required this.id,
    required this.hadithNumber,
    required this.hadithNumberInChapter,
    required this.textArabic,
    required this.textBangla,
    required this.textEnglish,
    required this.titleBangla,
    required this.titleEnglish,
    required this.narrator,
    required this.grade,
    required this.gradeBangla,
    required this.takhrij,
    required this.authorBangla,
    required this.authorEnglish,
    required this.sourceBangla,
    required this.sourceEnglish,
    required this.sectionNameBangla,
    required this.explanationEnglish,
  });

  final String id;
  final int hadithNumber;
  final int hadithNumberInChapter;
  final String textArabic;
  final String textBangla;
  final String textEnglish;
  final String titleBangla;
  final String titleEnglish;

  /// Bangla narrator name.
  final String narrator;

  /// e.g. `Sahih`.
  final String grade;

  /// e.g. `সহিহ (Sahih)`.
  final String gradeBangla;

  /// Reference line, e.g. `[1] সহীহুল বুখারী ২৪, ...`.
  final String takhrij;
  final String authorBangla;
  final String authorEnglish;
  final String sourceBangla;
  final String sourceEnglish;
  final String sectionNameBangla;
  final String explanationEnglish;
}
