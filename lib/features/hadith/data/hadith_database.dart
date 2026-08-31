import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models/hadith_bookmark.dart';
import 'models/hadith_entry.dart';

/// On-device SQLite store for downloaded hadith e-books.
///
/// A book's text is parsed from its bundled source file into [_entriesTable]
/// the first time the user opens it (see `HadithBookDownloader`). Every later
/// open reads straight from here, so a downloaded book works fully offline.
class HadithDatabase {
  HadithDatabase._();

  factory HadithDatabase() => _instance;

  static final HadithDatabase _instance = HadithDatabase._();

  static const _fileName = 'hadith_books.db';
  static const _version = 2;
  static const _booksTable = 'hadith_books';
  static const _entriesTable = 'hadith_entries';
  static const _bookmarksTable = 'hadith_bookmarks';
  static const _bookmarkFoldersTable = 'hadith_bookmark_folders';
  static const _bookmarkFolderMapTable = 'hadith_bookmark_folder_map';

  Database? _db;

  Future<String> _localPath() async =>
      p.join(await getDatabasesPath(), _fileName);

  Future<Database> open() async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;

    final path = await _localPath();
    await Directory(p.dirname(path)).create(recursive: true);
    return _db = await openDatabase(
      path,
      version: _version,
      onCreate: (db, _) async {
        await _createSchema(db);
        await _createBookmarkSchema(db);
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) await _createBookmarkSchema(db);
      },
    );
  }

  Future<void> _createBookmarkSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $_bookmarksTable (
        book_slug TEXT NOT NULL,
        hadith_no INTEGER NOT NULL,
        title_ar TEXT,
        title_bn TEXT,
        saved_at INTEGER NOT NULL,
        PRIMARY KEY (book_slug, hadith_no)
      )
    ''');
    await db.execute('''
      CREATE TABLE $_bookmarkFoldersTable (
        name TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_bookmarkFolderMapTable (
        book_slug TEXT NOT NULL,
        hadith_no INTEGER NOT NULL,
        folder TEXT NOT NULL,
        PRIMARY KEY (book_slug, hadith_no, folder)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_hadith_bookmark_folder '
      'ON $_bookmarkFolderMapTable(folder)',
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $_booksTable (
        slug TEXT PRIMARY KEY,
        title_en TEXT NOT NULL,
        title_bn TEXT NOT NULL,
        hadith_count INTEGER NOT NULL,
        status TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_entriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_slug TEXT NOT NULL,
        hadith_no INTEGER NOT NULL,
        title_ar TEXT,
        title_bn TEXT,
        arabic_text TEXT,
        bangla_narrator TEXT,
        bangla_text TEXT,
        references_text TEXT,
        UNIQUE(book_slug, hadith_no)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_hadith_entries_book '
      'ON $_entriesTable(book_slug, hadith_no)',
    );
  }

  /// Whether [slug] has finished downloading and all of its rows are present.
  Future<bool> isBookReady(String slug) async {
    try {
      if (!await File(await _localPath()).exists()) return false;
      final db = await open();
      final book = await db.query(
        _booksTable,
        where: 'slug = ?',
        whereArgs: [slug],
        limit: 1,
      );
      if (book.isEmpty || book.first['status'] != 'complete') return false;

      final expected = (book.first['hadith_count'] as int?) ?? 0;
      final actual = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM $_entriesTable WHERE book_slug = ?',
          [slug],
        ),
      );
      return expected > 0 && (actual ?? 0) >= expected;
    } catch (_) {
      return false;
    }
  }

  Future<Set<String>> downloadedSlugs() async {
    try {
      if (!await File(await _localPath()).exists()) return {};
      final db = await open();
      final rows = await db.query(
        _booksTable,
        columns: ['slug'],
        where: "status = 'complete'",
      );
      return {for (final row in rows) row['slug'] as String};
    } catch (_) {
      return {};
    }
  }

  /// How many rows of [slug] are already written (used to show resume progress).
  Future<int> savedEntryCount(String slug) async {
    final db = await open();
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $_entriesTable WHERE book_slug = ?',
            [slug],
          ),
        ) ??
        0;
  }

  /// Writes a batch of hadith rows for [slug]; re-running replaces on the
  /// (book_slug, hadith_no) key so retries never duplicate.
  Future<void> insertEntries(
    String slug,
    List<Map<String, Object?>> rows,
  ) async {
    final db = await open();
    await db.transaction((txn) async {
      for (final row in rows) {
        await txn.insert(_entriesTable, {
          'book_slug': slug,
          ...row,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> markBookComplete({
    required String slug,
    required String titleEn,
    required String titleBn,
    required int hadithCount,
  }) async {
    final db = await open();
    await db.insert(_booksTable, {
      'slug': slug,
      'title_en': titleEn,
      'title_bn': titleBn,
      'hadith_count': hadithCount,
      'status': 'complete',
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<HadithEntry>> entries(String slug) async {
    final db = await open();
    final rows = await db.query(
      _entriesTable,
      where: 'book_slug = ?',
      whereArgs: [slug],
      orderBy: 'hadith_no ASC',
    );
    return [for (final row in rows) HadithEntry.fromRow(row)];
  }

  Future<void> deleteBook(String slug) async {
    final db = await open();
    await db.delete(_entriesTable, where: 'book_slug = ?', whereArgs: [slug]);
    await db.delete(_booksTable, where: 'slug = ?', whereArgs: [slug]);
  }

  // --- Bookmarks -------------------------------------------------------------

  /// Every bookmarked hadith with its folders, newest-saved first. Folders
  /// include the reserved [HadithBookmark.singleFolder] when the hadith was
  /// saved with the per-hadith icon.
  Future<List<HadithBookmark>> bookmarks() async {
    final db = await open();
    final rows = await db.query(_bookmarksTable, orderBy: 'saved_at DESC');
    final map = await db.query(_bookmarkFolderMapTable);

    final foldersByKey = <String, List<String>>{};
    for (final m in map) {
      final key = '${m['book_slug']}#${m['hadith_no']}';
      (foldersByKey[key] ??= <String>[]).add(m['folder'] as String);
    }

    return [
      for (final r in rows)
        HadithBookmark(
          bookSlug: r['book_slug'] as String,
          hadithNo: r['hadith_no'] as int,
          titleAr: (r['title_ar'] as String?) ?? '',
          titleBn: (r['title_bn'] as String?) ?? '',
          savedAt: DateTime.fromMillisecondsSinceEpoch(r['saved_at'] as int),
          folders:
              foldersByKey['${r['book_slug']}#${r['hadith_no']}'] ?? const [],
        ),
    ];
  }

  Future<Set<String>> _foldersFor(
    DatabaseExecutor db,
    String slug,
    int hadithNo,
  ) async {
    final rows = await db.query(
      _bookmarkFolderMapTable,
      columns: ['folder'],
      where: 'book_slug = ? AND hadith_no = ?',
      whereArgs: [slug, hadithNo],
    );
    return {for (final r in rows) r['folder'] as String};
  }

  /// User folders the hadith is filed under (excludes the single-bookmark
  /// marker).
  Future<Set<String>> foldersFor(String slug, int hadithNo) async {
    final all = await _foldersFor(await open(), slug, hadithNo);
    return all..remove(HadithBookmark.singleFolder);
  }

  Future<bool> isSingleBookmarked(String slug, int hadithNo) async {
    final db = await open();
    final rows = await db.query(
      _bookmarkFolderMapTable,
      columns: ['folder'],
      where: 'book_slug = ? AND hadith_no = ? AND folder = ?',
      whereArgs: [slug, hadithNo, HadithBookmark.singleFolder],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// User folder names: the default, any created and any still in use.
  Future<List<String>> bookmarkFolders() async {
    final db = await open();
    final created = await db.query(
      _bookmarkFoldersTable,
      columns: ['name'],
      orderBy: 'created_at ASC',
    );
    final used = await db.rawQuery(
      'SELECT DISTINCT folder FROM $_bookmarkFolderMapTable',
    );
    final names = <String>{
      HadithBookmark.defaultFolder,
      for (final r in created) r['name'] as String,
      for (final r in used) r['folder'] as String,
    }..remove(HadithBookmark.singleFolder);
    final ordered = names.toList()
      ..remove(HadithBookmark.defaultFolder)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return [HadithBookmark.defaultFolder, ...ordered];
  }

  Future<void> createBookmarkFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty ||
        trimmed == HadithBookmark.defaultFolder ||
        trimmed == HadithBookmark.singleFolder) {
      return;
    }
    final db = await open();
    await db.insert(_bookmarkFoldersTable, {
      'name': trimmed,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Saved-hadith count per user folder (excludes the single-bookmark marker).
  Future<Map<String, int>> bookmarkFolderCounts() async {
    final db = await open();
    final rows = await db.rawQuery(
      'SELECT folder, COUNT(*) AS c FROM $_bookmarkFolderMapTable '
      'WHERE folder != ? GROUP BY folder',
      [HadithBookmark.singleFolder],
    );
    return {for (final r in rows) r['folder'] as String: r['c'] as int};
  }

  /// Rewrites the full folder membership of a hadith. An empty set deletes the
  /// bookmark row.
  Future<void> _setMemberships(
    HadithBookmark bookmark,
    Set<String> folders,
  ) async {
    final db = await open();
    await db.transaction((txn) async {
      await txn.delete(
        _bookmarkFolderMapTable,
        where: 'book_slug = ? AND hadith_no = ?',
        whereArgs: [bookmark.bookSlug, bookmark.hadithNo],
      );
      if (folders.isEmpty) {
        await txn.delete(
          _bookmarksTable,
          where: 'book_slug = ? AND hadith_no = ?',
          whereArgs: [bookmark.bookSlug, bookmark.hadithNo],
        );
        return;
      }
      final existing = await txn.query(
        _bookmarksTable,
        columns: ['title_ar', 'title_bn', 'saved_at'],
        where: 'book_slug = ? AND hadith_no = ?',
        whereArgs: [bookmark.bookSlug, bookmark.hadithNo],
        limit: 1,
      );
      final prev = existing.isNotEmpty ? existing.first : null;
      final titleAr = bookmark.titleAr.isNotEmpty
          ? bookmark.titleAr
          : (prev?['title_ar'] as String?) ?? '';
      final titleBn = bookmark.titleBn.isNotEmpty
          ? bookmark.titleBn
          : (prev?['title_bn'] as String?) ?? '';
      final savedAt =
          (prev?['saved_at'] as int?) ?? bookmark.savedAt.millisecondsSinceEpoch;
      await txn.insert(_bookmarksTable, {
        'book_slug': bookmark.bookSlug,
        'hadith_no': bookmark.hadithNo,
        'title_ar': titleAr,
        'title_bn': titleBn,
        'saved_at': savedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      for (final folder in folders) {
        await txn.insert(_bookmarkFolderMapTable, {
          'book_slug': bookmark.bookSlug,
          'hadith_no': bookmark.hadithNo,
          'folder': folder,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  /// Adds/removes the per-hadith (single) bookmark, keeping any user folders
  /// intact. Returns the new state.
  Future<bool> toggleSingleBookmark(HadithBookmark bookmark) async {
    final current = await _foldersFor(
      await open(),
      bookmark.bookSlug,
      bookmark.hadithNo,
    );
    final nowOn = !current.contains(HadithBookmark.singleFolder);
    if (nowOn) {
      current.add(HadithBookmark.singleFolder);
    } else {
      current.remove(HadithBookmark.singleFolder);
    }
    await _setMemberships(bookmark, current);
    return nowOn;
  }

  /// Files [bookmark] under exactly [folders] (user folders), preserving the
  /// single-bookmark marker if present.
  Future<void> setBookmarkFolders(
    HadithBookmark bookmark,
    Set<String> folders,
  ) async {
    final current = await _foldersFor(
      await open(),
      bookmark.bookSlug,
      bookmark.hadithNo,
    );
    final next = {
      ...folders.where((f) => f != HadithBookmark.singleFolder),
      if (current.contains(HadithBookmark.singleFolder))
        HadithBookmark.singleFolder,
    };
    await _setMemberships(bookmark, next);
  }

  HadithBookmark _stub(String slug, int hadithNo) => HadithBookmark(
    bookSlug: slug,
    hadithNo: hadithNo,
    titleAr: '',
    titleBn: '',
    savedAt: DateTime.now(),
  );

  /// Removes only the per-hadith (single) bookmark.
  Future<void> removeSingleBookmark(String slug, int hadithNo) async {
    final current = await _foldersFor(await open(), slug, hadithNo);
    current.remove(HadithBookmark.singleFolder);
    await _setMemberships(_stub(slug, hadithNo), current);
  }

  /// Removes the hadith from a single user folder.
  Future<void> removeBookmarkFromFolder(
    String slug,
    int hadithNo,
    String folder,
  ) async {
    final current = await _foldersFor(await open(), slug, hadithNo);
    current.remove(folder);
    await _setMemberships(_stub(slug, hadithNo), current);
  }

  Future<void> removeBookmark(String slug, int hadithNo) async {
    final db = await open();
    await db.transaction((txn) async {
      await txn.delete(
        _bookmarkFolderMapTable,
        where: 'book_slug = ? AND hadith_no = ?',
        whereArgs: [slug, hadithNo],
      );
      await txn.delete(
        _bookmarksTable,
        where: 'book_slug = ? AND hadith_no = ?',
        whereArgs: [slug, hadithNo],
      );
    });
  }
}
