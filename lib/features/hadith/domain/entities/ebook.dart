/// One e-book of the hadith library's e-book shelf (`GET /ebooks`).
class Ebook {
  const Ebook({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.coverImageUrl,
    required this.pdfFileUrl,
    required this.totalPages,
    required this.description,
    required this.language,
    required this.displayOrder,
    required this.isActive,
  });

  final String id;
  final String title;
  final String author;
  final String category;
  final String coverImageUrl;
  final String pdfFileUrl;
  final int totalPages;
  final String description;
  final String language;
  final int displayOrder;
  final bool isActive;
}
