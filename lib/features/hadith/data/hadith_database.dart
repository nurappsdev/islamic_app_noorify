import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

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
  static const _version = 1;
  static const _booksTable = 'hadith_books';
  static const _entriesTable = 'hadith_entries';

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
      onCreate: (db, _) => _createSchema(db),
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
}
