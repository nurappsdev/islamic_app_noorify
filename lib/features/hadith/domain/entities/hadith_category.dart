/// One category (chapter) of a hadith collection
/// (`GET /hadiths/categories?bookId=...`).
class HadithCategory {
  const HadithCategory({
    required this.id,
    required this.bookId,
    required this.name,
    required this.nameBangla,
    required this.nameArabic,
    required this.sectionNumber,
    required this.displayOrder,
    required this.totalHadiths,
    required this.totalSubCategories,
  });

  final String id;
  final String bookId;
  final String name;
  final String nameBangla;
  final String nameArabic;
  final int sectionNumber;
  final int displayOrder;
  final int totalHadiths;
  final int totalSubCategories;
}
