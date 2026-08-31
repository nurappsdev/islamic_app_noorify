import 'dart:io';

import 'package:http/http.dart' as http;

import 'quran_offline_database.dart';
import 'quran_reader_service.dart';
import 'quran_storage.dart';

class AudioDownloadProgress {
  const AudioDownloadProgress(this.done, this.total);

  final int done;
  final int total;

  double? get fraction => total > 0 ? (done / total).clamp(0.0, 1.0) : null;
}

class AudioDownloadException implements Exception {
  const AudioDownloadException(this.message);

  final String message;

  @override
  String toString() => 'AudioDownloadException: $message';
}

/// Downloads a surah's recitation (one MP3 per ayah, for a given reciter) to
/// the device and records only the file's metadata in [QuranOfflineDatabase].
///
/// Interrupt-safe: each file streams to a `.part` temp path and is renamed
/// atomically on success; the database row is written `complete` only after
/// that rename, so a re-run resumes cleanly and never leaves a half file that
/// looks finished.
class QuranAudioDownloader {
  QuranAudioDownloader({
    QuranReaderService? readerService,
    QuranOfflineDatabase? database,
    this.storage = const QuranStorage(),
    http.Client? client,
  }) : _reader = readerService ?? QuranComReaderService(),
       _db = database ?? QuranOfflineDatabase(),
       _client = client ?? http.Client();

  final QuranReaderService _reader;
  final QuranOfflineDatabase _db;
  final QuranStorage storage;
  final http.Client _client;

  /// Al-Fatiha and At-Tawbah are the two surahs that do not open with the
  /// Basmala, so no separate Bismillah clip is downloaded or played for them.
  static const _surahsWithoutBismillah = {1, 9};

  static const _bismillahVerseKey = 'bismillah';

  Stream<AudioDownloadProgress> downloadSurah({
    required int reciterId,
    required int surahNo,
  }) async* {
    final List<({String verseKey, String url})> files;
    try {
      files = await _reader.loadChapterAudioFiles(reciterId, surahNo);
    } catch (_) {
      throw const AudioDownloadException(
        'Could not reach the audio server. Check your connection.',
      );
    }
    if (files.isEmpty) {
      throw const AudioDownloadException('No audio available for this surah.');
    }

    final needsBismillah = !_surahsWithoutBismillah.contains(surahNo);
    final total = files.length + (needsBismillah ? 1 : 0);
    var done = 0;
    yield AudioDownloadProgress(done, total);

    if (needsBismillah) {
      await _downloadBismillah(reciterId);
      done++;
      yield AudioDownloadProgress(done, total);
    }

    for (final file in files) {
      final ayahNo = _ayahOf(file.verseKey);
      final finalPath = await storage.ayahFilePath(reciterId, surahNo, ayahNo);

      final existing = await _db.audioRow(reciterId, file.verseKey);
      final alreadyDone =
          existing != null &&
          existing['status'] == 'complete' &&
          await File(existing['local_path'] as String? ?? finalPath).exists();
      if (alreadyDone) {
        done++;
        yield AudioDownloadProgress(done, total);
        continue;
      }

      await _downloadOne(
        reciterId: reciterId,
        surahNo: surahNo,
        ayahNo: ayahNo,
        verseKey: file.verseKey,
        remoteUrl: file.url,
        finalPath: finalPath,
      );
      done++;
      yield AudioDownloadProgress(done, total);
    }
  }

  Future<void> _downloadOne({
    required int reciterId,
    required int surahNo,
    required int ayahNo,
    required String verseKey,
    required String remoteUrl,
    required String finalPath,
  }) async {
    final partFile = File('$finalPath.part');
    try {
      final request = http.Request('GET', Uri.parse(remoteUrl));
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw AudioDownloadException('Audio download failed ($verseKey).');
      }
      final sink = partFile.openWrite();
      try {
        await sink.addStream(response.stream);
      } finally {
        await sink.close();
      }
      final target = File(finalPath);
      if (await target.exists()) await target.delete();
      await partFile.rename(finalPath);

      await _db.upsertAudioRow(
        reciterId: reciterId,
        surahId: surahNo,
        ayahNumber: ayahNo,
        verseKey: verseKey,
        remoteUrl: remoteUrl,
        localPath: finalPath,
        status: 'complete',
      );
    } catch (e) {
      if (await partFile.exists()) {
        try {
          await partFile.delete();
        } catch (_) {}
      }
      if (e is AudioDownloadException) rethrow;
      throw AudioDownloadException('Audio download failed ($verseKey).');
    }
  }

  /// Downloads the reciter's Bismillah clip once (Al-Fatiha 1:1 is the
  /// Basmala). Re-runs are a no-op once the file is on disk.
  Future<void> _downloadBismillah(int reciterId) async {
    final finalPath = await storage.bismillahFilePath(reciterId);
    final existing = await _db.audioRow(reciterId, _bismillahVerseKey);
    if (existing != null &&
        existing['status'] == 'complete' &&
        await File(existing['local_path'] as String? ?? finalPath).exists()) {
      return;
    }
    final String url;
    try {
      url = await _reader.loadAyahAudioUrl(reciterId, '1:1');
    } catch (_) {
      throw const AudioDownloadException(
        'Could not reach the audio server. Check your connection.',
      );
    }
    await _downloadOne(
      reciterId: reciterId,
      surahNo: 0,
      ayahNo: 0,
      verseKey: _bismillahVerseKey,
      remoteUrl: url,
      finalPath: finalPath,
    );
  }

  /// Local file path for a downloaded ayah, or null if it must be streamed.
  Future<String?> localPathFor({
    required int reciterId,
    required String verseKey,
  }) async {
    final row = await _db.audioRow(reciterId, verseKey);
    if (row == null || row['status'] != 'complete') return null;
    final path = row['local_path'] as String?;
    if (path == null) return null;
    return await File(path).exists() ? path : null;
  }

  /// Local path to the reciter's Bismillah clip, or null if not downloaded.
  Future<String?> localBismillahPath(int reciterId) =>
      localPathFor(reciterId: reciterId, verseKey: _bismillahVerseKey);

  Future<AudioDownloadProgress> surahStatus({
    required int reciterId,
    required int surahNo,
    required int totalAyah,
  }) async {
    final done = await _db.completedAudioCount(reciterId, surahNo);
    return AudioDownloadProgress(done, totalAyah);
  }

  /// Whether every ayah of the surah — plus the reciter's Bismillah clip,
  /// where the surah opens with the Basmala — is on the device.
  Future<bool> isSurahComplete({
    required int reciterId,
    required int surahNo,
    required int totalAyah,
  }) async {
    if (totalAyah <= 0) return false;
    final done = await _db.completedAudioCount(reciterId, surahNo);
    if (done < totalAyah) return false;
    if (_surahsWithoutBismillah.contains(surahNo)) return true;
    return await localBismillahPath(reciterId) != null;
  }

  static int _ayahOf(String verseKey) {
    final parts = verseKey.split(':');
    return parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  }
}
