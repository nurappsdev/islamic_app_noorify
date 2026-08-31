import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves the on-device directories used to hold downloaded Quran audio.
///
/// Audio files live under the app documents directory (never in SQLite):
/// `<documents>/quran_audio/{reciterId}/{surahNo}/{ayahNo}.mp3`.
class QuranStorage {
  const QuranStorage();

  Future<Directory> _root() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'quran_audio'));
  }

  /// Directory for one surah of one reciter, created if missing.
  Future<Directory> audioDir(int reciterId, int surahNo) async {
    final dir = Directory(
      p.join((await _root()).path, '$reciterId', '$surahNo'),
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Final path for a single ayah's audio file (may not exist yet).
  Future<String> ayahFilePath(int reciterId, int surahNo, int ayahNo) async {
    final dir = await audioDir(reciterId, surahNo);
    return p.join(dir.path, '$ayahNo.mp3');
  }

  /// Final path for a reciter's Bismillah clip, shared by every surah that
  /// opens with the Basmala. Stored once per reciter (may not exist yet).
  Future<String> bismillahFilePath(int reciterId) async {
    final dir = Directory(p.join((await _root()).path, '$reciterId'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return p.join(dir.path, 'bismillah.mp3');
  }

  /// Removes every downloaded audio file (metadata rows are cleared separately).
  Future<void> clearAll() async {
    final root = await _root();
    if (await root.exists()) await root.delete(recursive: true);
  }
}
