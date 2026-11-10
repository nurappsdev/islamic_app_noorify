/// One sub-category (chapter) of a hadith category
/// (`GET /hadiths/categories/{id}/subcategories`).
class HadithSubCategory {
  const HadithSubCategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.nameBangla,
    required this.nameEnglish,
    required this.nameArabic,
    required this.chapterNumber,
    required this.displayOrder,
    required this.totalHadiths,
  });

  final String id;
  final String categoryId;
  final String name;
  final String nameBangla;
  final String nameEnglish;
  final String nameArabic;
  final int chapterNumber;
  final int displayOrder;
  final int totalHadiths;
}
