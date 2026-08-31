/// A single bookmarked hadith and the folders it belongs to.
///
/// A hadith can be saved two independent ways:
/// * the per-hadith bookmark icon — membership of the reserved [singleFolder],
///   surfaced in the "Hadith" tab of the Saved screen;
/// * the app-bar bookmark — membership of one or more user folders, surfaced
///   in the "Folder" tab.
class HadithBookmark {
  const HadithBookmark({
    required this.bookSlug,
    required this.hadithNo,
    required this.titleAr,
    required this.titleBn,
    required this.savedAt,
    this.folders = const [],
  });

  /// Reserved folder marking a quick per-hadith bookmark (never shown as a
  /// folder in the UI).
  static const singleFolder = '__single__';

  /// Default user folder offered by the app-bar bookmark sheet.
  static const defaultFolder = 'Favorite';

  final String bookSlug;
  final int hadithNo;
  final String titleAr;
  final String titleBn;
  final DateTime savedAt;
  final List<String> folders;

  /// Identity of the bookmarked hadith (`"<book slug>#<hadith no>"`).
  String get key => '$bookSlug#$hadithNo';

  String get displayTitle => titleBn.isNotEmpty ? titleBn : titleAr;

  bool get isSingleBookmarked => folders.contains(singleFolder);

  List<String> get userFolders =>
      folders.where((f) => f != singleFolder).toList();

  HadithBookmark copyWith({List<String>? folders, DateTime? savedAt}) =>
      HadithBookmark(
        bookSlug: bookSlug,
        hadithNo: hadithNo,
        titleAr: titleAr,
        titleBn: titleBn,
        savedAt: savedAt ?? this.savedAt,
        folders: folders ?? this.folders,
      );
}
