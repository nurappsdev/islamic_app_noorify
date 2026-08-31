import 'hadith_database.dart';
import 'models/hadith_bookmark.dart';

export 'models/hadith_bookmark.dart';

/// Bookmarked-hadith storage, backed by the SQLite [HadithDatabase].
///
/// Two independent kinds of save:
/// * [toggleSingle] / [isSingleBookmarked] — the per-hadith bookmark icon
///   (surfaced in the Saved screen's "Hadith" tab);
/// * [saveToFolders] with [folders] / [folderCounts] — the app-bar bookmark
///   sheet (surfaced in the "Folder" tab).
class HadithBookmarkStore {
  HadithBookmarkStore._();

  factory HadithBookmarkStore() => _instance;

  static final HadithBookmarkStore _instance = HadithBookmarkStore._();

  static const defaultFolder = HadithBookmark.defaultFolder;
  static const singleFolder = HadithBookmark.singleFolder;

  final HadithDatabase _db = HadithDatabase();

  /// Every saved hadith (both kinds), newest first.
  Future<List<HadithBookmark>> all() => _db.bookmarks();

  Future<List<String>> folders() => _db.bookmarkFolders();

  Future<void> createFolder(String name) => _db.createBookmarkFolder(name);

  Future<Map<String, int>> folderCounts() => _db.bookmarkFolderCounts();

  /// User folders a hadith is filed under (excludes the single-bookmark marker).
  Future<Set<String>> foldersFor(String slug, int hadithNo) =>
      _db.foldersFor(slug, hadithNo);

  // --- Per-hadith bookmark icon --------------------------------------------

  Future<bool> isSingleBookmarked(String slug, int hadithNo) =>
      _db.isSingleBookmarked(slug, hadithNo);

  /// Toggles the per-hadith bookmark, keeping folder memberships intact.
  Future<bool> toggleSingle(HadithBookmark bookmark) =>
      _db.toggleSingleBookmark(bookmark);

  Future<void> removeSingle(String slug, int hadithNo) =>
      _db.removeSingleBookmark(slug, hadithNo);

  // --- App-bar bookmark sheet --------------------------------------------

  /// Files [bookmark] under exactly [folders] (user folders); the per-hadith
  /// bookmark, if set, is preserved.
  Future<void> saveToFolders(HadithBookmark bookmark, Set<String> folders) =>
      _db.setBookmarkFolders(bookmark, folders);

  Future<void> removeFromFolder(String slug, int hadithNo, String folder) =>
      _db.removeBookmarkFromFolder(slug, hadithNo, folder);
}
