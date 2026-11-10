import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Caches alarm ringtones on the device, keyed by their catalog
/// `ringtoneId`, so a scheduled alarm plays the user's chosen sound
/// instantly from local storage instead of streaming it from the backend at
/// the exact moment it fires (which is unreliable — slow or absent network,
/// especially for an early-morning Fajr alarm).
///
/// Mirrors `EbookDownloader`'s atomic-download pattern. Every method is
/// best-effort and never throws: alarm playback must never crash or block on
/// a failed download — `AlarmScheduler` falls back to a bundled ringtone
/// when nothing is cached (see `_playChosenRingtone`).
abstract final class RingtoneCache {
  static Future<File> _fileFor(String ringtoneId) async {
    final dir = await getApplicationDocumentsDirectory();
    final name = ringtoneId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return File('${dir.path}/ringtones/$name.audio');
  }

  /// The cached file for [ringtoneId], or `null` when it hasn't been
  /// downloaded (or a previous download never finished).
  static Future<File?> cachedFile(String ringtoneId) async {
    if (ringtoneId.isEmpty) return null;
    try {
      final file = await _fileFor(ringtoneId);
      return await file.exists() && await file.length() > 0 ? file : null;
    } catch (_) {
      return null;
    }
  }

  /// Downloads [audioUrl] into [ringtoneId]'s cache slot if it isn't already
  /// there. Safe to call every time a ringtone is selected or previewed — a
  /// no-op once cached.
  static Future<void> ensureCached(String ringtoneId, String audioUrl) async {
    if (ringtoneId.isEmpty || audioUrl.isEmpty) return;
    try {
      if (await cachedFile(ringtoneId) != null) return;
      final target = await _fileFor(ringtoneId);
      await target.parent.create(recursive: true);
      final partial = File('${target.path}.part');
      try {
        await Dio().download(audioUrl, partial.path);
        await partial.rename(target.path);
      } catch (_) {
        if (await partial.exists()) await partial.delete();
      }
    } catch (_) {
      // Best-effort: the alarm falls back to the bundled ringtone.
    }
  }
}
