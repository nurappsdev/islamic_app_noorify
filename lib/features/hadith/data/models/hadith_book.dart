/// A hadith e-book shown on the Hadith library "E-book" shelf.
///
/// [assetXmlPath] points at the bundled source file that is parsed into the
/// local SQLite database the first time the user opens the book. Books without
/// an asset are catalogue placeholders ([isAvailable] is false).
class HadithBook {
  const HadithBook({
    required this.slug,
    required this.titleEn,
    required this.titleBn,
    required this.authorEn,
    required this.hadithCount,
    this.assetXmlPath,
    this.assetReferenceXmlPath,
  });

  final String slug;
  final String titleEn;
  final String titleBn;
  final String authorEn;
  final int hadithCount;
  final String? assetXmlPath;

  /// Optional bundled file with the book's publication details (author,
  /// translator, editors, publisher, year) shown in the reader drawer.
  final String? assetReferenceXmlPath;

  bool get isAvailable => assetXmlPath != null;
}
