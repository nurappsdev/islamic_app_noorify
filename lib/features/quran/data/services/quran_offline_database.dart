import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Which step of the one-time offline download is running.
enum QuranSetupPhase { reading, building }

class QuranSetupProgress {
  const QuranSetupProgress(this.phase, this.done, this.total);

  final QuranSetupPhase phase;
  final int done;
  final int total;

  double? get fraction =>
      total > 0 ? (done / total).clamp(0.0, 1.0) : null;
}

class QuranSetupException implements Exception {
  const QuranSetupException(this.message);

  final String message;

  @override
  String toString() => 'QuranSetupException: $message';
}

/// Owns the on-device SQLite copy of the Quran (Arabic text plus the English
/// and Bengali translations).
///
/// The data is fetched from the app's existing Quran API the first time the
/// user taps "Download for offline" (see `QuranOfflineDownloader`) and written
/// here; every later launch reads from this database directly. Downloaded audio
/// is stored as files on disk — only its metadata lives in the `audio_downloads`
/// table.
class QuranOfflineDatabase {
  QuranOfflineDatabase._();

  factory QuranOfflineDatabase() => _instance;

  static final QuranOfflineDatabase _instance = QuranOfflineDatabase._();

  static const _fileName = 'quran_offline.db';
  static const _version = 2;
  static const _expectedAyahCount = 6236;
  static const surahCount = 114;

  Database? _db;

  Future<String> _localPath() async =>
      p.join(await getDatabasesPath(), _fileName);

  /// Opens (creating/upgrading as needed) the local database.
  Future<Database> open() async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;

    final path = await _localPath();
    await Directory(p.dirname(path)).create(recursive: true);
    return _db = await openDatabase(
      path,
      version: _version,
      onCreate: (db, version) => _createSchema(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 was an XML-derived, Arabic-only build with no translations.
        // The data is fully re-downloadable, so recreate from scratch.
        await db.execute('DROP TABLE IF EXISTS quran_text');
        await db.execute('DROP TABLE IF EXISTS surah_meta');
        await db.execute('DROP TABLE IF EXISTS audio_downloads');
        await _createSchema(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE quran_text (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_id INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        text_ar TEXT NOT NULL,
        text_en TEXT,
        text_bn TEXT,
        UNIQUE(surah_id, ayah_number)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_quran_surah_ayah ON quran_text(surah_id, ayah_number)',
    );
    await db.execute('''
      CREATE TABLE surah_meta (
        number INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        name_arabic TEXT NOT NULL,
        translation TEXT NOT NULL,
        revelation_place TEXT NOT NULL,
        total_ayah INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE audio_downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reciter_id INTEGER NOT NULL,
        surah_id INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        verse_key TEXT NOT NULL,
        remote_url TEXT NOT NULL,
        local_path TEXT NOT NULL,
        status TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(reciter_id, surah_id, ayah_number)
      )
    ''');
  }

  /// Whether the full Quran text + translations have already been downloaded.
  Future<bool> isReady() async {
    try {
      if (!await File(await _localPath()).exists()) return false;
      final db = await open();
      final metaCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM surah_meta'),
      );
      if ((metaCount ?? 0) < surahCount) return false;

      final incomplete = Sqflite.firstIntValue(
        await db.rawQuery('''
          SELECT COUNT(*) FROM surah_meta m
          WHERE m.total_ayah <>
            (SELECT COUNT(*) FROM quran_text t WHERE t.surah_id = m.number)
        '''),
      );
      if ((incomplete ?? 1) != 0) return false;

      final ayahRows = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM quran_text'),
      );
      if ((ayahRows ?? 0) < _expectedAyahCount) return false;

      final missingBn = Sqflite.firstIntValue(
        await db.rawQuery(
          "SELECT COUNT(*) FROM quran_text WHERE text_bn IS NULL OR text_bn = ''",
        ),
      );
      return (missingBn ?? 1) == 0;
    } catch (_) {
      return false;
    }
  }

  /// Surah numbers whose ayah rows are fully written (used to resume a
  /// partial download without re-fetching completed surahs).
  Future<Set<int>> completedSurahIds() async {
    final db = await open();
    final rows = await db.rawQuery('''
      SELECT m.number AS number FROM surah_meta m
      WHERE m.total_ayah > 0
        AND m.total_ayah =
          (SELECT COUNT(*) FROM quran_text t WHERE t.surah_id = m.number)
    ''');
    return {for (final row in rows) row['number'] as int};
  }

  Future<int> surahMetaCount() async {
    final db = await open();
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM surah_meta'),
        ) ??
        0;
  }

  Future<void> upsertSurahMeta(List<Map<String, Object?>> rows) async {
    final db = await open();
    final batch = db.batch();
    for (final row in rows) {
      batch.insert(
        'surah_meta',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Writes every ayah of one surah in a single transaction. Re-running with
  /// the same surah replaces the existing rows (no duplicates).
  Future<void> upsertSurahText(
    int surahId,
    List<Map<String, Object?>> ayahRows,
  ) async {
    final db = await open();
    await db.transaction((txn) async {
      for (final row in ayahRows) {
        await txn.insert(
          'quran_text',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, Object?>>> surahMetaRows() async {
    final db = await open();
    return db.query('surah_meta', orderBy: 'number ASC');
  }

  Future<List<Map<String, Object?>>> surahTextRows(int surahId) async {
    final db = await open();
    return db.query(
      'quran_text',
      columns: ['ayah_number', 'text_ar', 'text_en', 'text_bn'],
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'ayah_number ASC',
    );
  }

  Future<Map<String, Object?>?> audioRow(
    int reciterId,
    String verseKey,
  ) async {
    final db = await open();
    final rows = await db.query(
      'audio_downloads',
      where: 'reciter_id = ? AND verse_key = ?',
      whereArgs: [reciterId, verseKey],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> upsertAudioRow({
    required int reciterId,
    required int surahId,
    required int ayahNumber,
    required String verseKey,
    required String remoteUrl,
    required String localPath,
    required String status,
  }) async {
    final db = await open();
    await db.insert('audio_downloads', {
      'reciter_id': reciterId,
      'surah_id': surahId,
      'ayah_number': ayahNumber,
      'verse_key': verseKey,
      'remote_url': remoteUrl,
      'local_path': localPath,
      'status': status,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> completedAudioCount(int reciterId, int surahId) async {
    final db = await open();
    return Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM audio_downloads "
            "WHERE reciter_id = ? AND surah_id = ? AND status = 'complete'",
            [reciterId, surahId],
          ),
        ) ??
        0;
  }

  /// Removes the built database (used to fully reset offline data).
  Future<void> delete() async {
    await _db?.close();
    _db = null;
    final file = File(await _localPath());
    if (await file.exists()) await file.delete();
  }
}
