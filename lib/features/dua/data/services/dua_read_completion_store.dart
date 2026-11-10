import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

/// The duas the signed-in user has marked read, kept on the device for good.
///
/// Ticking "Read / Completed" is a final answer about that dua: reopening it
/// shows the box already checked, with the duration that was recorded, and
/// starts no new timer — so no further reading time is ever reported for it.
/// Only a successful report writes here (see `DuaReadingTracker.complete`),
/// which is what keeps the checkbox honest: what it shows as read is what
/// the server was told about.
///
/// The record belongs to whoever was signed in, so [SessionCleaner] clears
/// both this map and its stored key on sign-out and the next account starts
/// with none. It lives on this device alone: the API has no per-dua read
/// flag to restore it from after a reinstall.
class DuaReadCompletionStore {
  DuaReadCompletionStore();

  static final shared = DuaReadCompletionStore();

  /// The SharedPreferences key. Cleared on sign-out.
  static const key = 'dua_reads_completed';

  /// Far above the number of duas the catalog holds; a guard against a
  /// corrupt or runaway file rather than an expected limit. The earliest
  /// records are dropped first.
  @visibleForTesting
  static const maxEntries = 5000;

  /// Dua id -> the seconds that were reported when it was marked read.
  final _seconds = <String, int>{};
  Future<void>? _restoring;
  bool _restored = false;

  /// Bumped by [clear] so a restore already in flight cannot bring the
  /// previous account's records back after sign-out.
  int _generation = 0;

  /// Whether the device's record has been read. Until it has, [isCompleted]
  /// only knows what this run marked.
  bool get isRestored => _restored;

  bool isCompleted(String duaId) => _seconds.containsKey(duaId);

  /// The reading time recorded when [duaId] was marked read, or 0.
  int secondsFor(String duaId) => _seconds[duaId] ?? 0;

  /// Loads the record left by earlier launches. Runs once.
  Future<void> restore() => _restoring ??= _restore();

  Future<void> _restore() async {
    final generation = _generation;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      // Signed out while storage was loading: those records are gone.
      if (generation != _generation) return;
      final decoded = (raw == null || raw.isEmpty) ? null : jsonDecode(raw);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          final duaId = entry.key.toString();
          final seconds = entry.value;
          if (duaId.isEmpty || seconds is! num) continue;
          // A dua marked read during this launch is the newer answer.
          _seconds.putIfAbsent(duaId, () => seconds.toInt());
        }
      }
    } catch (_) {
      // Nothing readable on this device: no dua is known to be read, and the
      // reader simply times the visit as it would the first time.
    }
    if (generation == _generation) _restored = true;
  }

  /// Records [duaId] as read for good, with the [seconds] just reported.
  ///
  /// The device's record is loaded first, so writing one dua can never erase
  /// another launch's.
  Future<void> markCompleted(String duaId, {required int seconds}) async {
    if (duaId.isEmpty) return;
    await restore();
    final generation = _generation;
    final existing = _seconds[duaId];
    if (existing != null && existing >= seconds) return;
    _seconds[duaId] = seconds < 0 ? 0 : seconds;
    while (_seconds.length > maxEntries) {
      _seconds.remove(_seconds.keys.first);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      if (generation != _generation) return;
      await prefs.setString(key, jsonEncode(_seconds));
    } catch (_) {
      // Still read for this run; the next tick of the box tries again.
    }
  }

  /// Forgets every record — the session it belonged to has ended. The stored
  /// key itself is removed by [SessionCleaner] alongside the other per-user
  /// keys.
  void clear() {
    _generation++;
    _seconds.clear();
    _restoring = null;
    _restored = false;
  }
}
