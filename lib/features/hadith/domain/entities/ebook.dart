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
    required this.publisher,
    required this.reference,
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
  final String publisher;
  final String reference;
  final int displayOrder;
  final bool isActive;

  /// Whether [pdfFileUrl] is something the app can actually fetch.
  ///
  /// A record may carry a `blob:` URL - a handle that only exists inside the
  /// browser tab that picked the file, so the PDF never reached storage and no
  /// HTTP client can resolve it. Treat anything that is not an absolute
  /// http(s) URL as a missing file, so the screen says so instead of offering
  /// a download that can only fail.
  bool get hasReadablePdf {
    final uri = Uri.tryParse(pdfFileUrl.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
