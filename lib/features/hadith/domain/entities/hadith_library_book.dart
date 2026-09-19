/// One hadith collection of the "Hadith library" (`GET /hadiths/books/lists`).
class HadithLibraryBook {
  const HadithLibraryBook({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.titleAr,
    required this.authorEn,
    required this.authorBn,
    required this.totalHadiths,
    required this.totalCategories,
    required this.totalSubCategories,
    required this.displayOrder,
  });

  final String id;
  final String titleEn;
  final String titleBn;
  final String titleAr;
  final String authorEn;
  final String authorBn;
  final int totalHadiths;
  final int totalCategories;
  final int totalSubCategories;
  final int displayOrder;
}
