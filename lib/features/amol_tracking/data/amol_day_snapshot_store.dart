import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The last checklist the server sent for each recent day, kept as the raw
/// `data` payload so it is read back through the very same
/// `AmolDailyDashboardModel.fromJson` a live response goes through.
///
/// One entry per `YYYY-MM-DD`, unlike a single-slot cache: the tracker has to
/// serve the day the user is looking at, and a new Fajr-to-Fajr day needs the
/// most recent day as the template to build an empty checklist from.
class AmolDaySnapshotStore {
  /// The one every repository and the remote data source use unless a test
  /// injects its own.
  static final shared = AmolDaySnapshotStore();

  static const key = 'offline_cache_amol_day_snapshots';

  /// Days kept before the oldest is dropped.
  static const _maxDays = 14;

  Future<void> _lock = Future.value();

  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _lock.then((_) => action());
    _lock = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// The stored payload for [dateIso], or `null`.
  Future<Map<String, dynamic>?> read(String dateIso) async {
    final all = await _readAll();
    final json = all[dateIso];
    return json is Map<String, dynamic> ? json : null;
  }

  /// The most recent stored day, whatever its date — the template a new day
  /// is built from. Returns its date and payload.
  Future<({String dateIso, Map<String, dynamic> json})?> latest() async {
    final all = await _readAll();
    if (all.isEmpty) return null;
    final dates = all.keys.toList()..sort();
    for (final date in dates.reversed) {
      final json = all[date];
      if (json is Map<String, dynamic>) return (dateIso: date, json: json);
    }
    return null;
  }

  /// Stores [json] as the known-good checklist for its own `dateIso`.
  Future<void> write(Map<String, dynamic> json) => _locked(() async {
    final dateIso = json['dateIso']?.toString();
    if (dateIso == null || dateIso.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = await _decodeAll(prefs);
      all[dateIso] = json;
      if (all.length > _maxDays) {
        final dates = all.keys.toList()..sort();
        for (final old in dates.take(all.length - _maxDays)) {
          all.remove(old);
        }
      }
      await prefs.setString(key, jsonEncode(all));
    } catch (_) {
      // Best-effort cache: never break a caller that just got a good
      // response.
    }
  });

  Future<Map<String, dynamic>> _readAll() async {
    try {
      return await _decodeAll(await SharedPreferences.getInstance());
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> _decodeAll(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }
}
