import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The last successfully-fetched JSON payload for one endpoint/scope, kept in
/// [SharedPreferences] under [cacheKey] so a repository can serve it back
/// when a later request fails (offline, server error, ...) instead of
/// surfacing an empty state.
///
/// Callers round-trip through the same `Model.fromJson` the live response
/// already goes through, so a cached value is parsed exactly like a fresh
/// one — there is no separate `toJson` to keep in sync.
///
/// Writes are monotonic: [save] only replaces what's stored when [at] is not
/// older than the timestamp already there, so a slow request that lands after
/// a newer one already wrote its result can never clobber it with stale data.
class LatestJsonCache {
  LatestJsonCache(this.cacheKey);

  final String cacheKey;

  String get _dataKey => 'offline_cache_${cacheKey}_json';
  String get _atKey => 'offline_cache_${cacheKey}_at_ms';

  /// Persists [json] as the latest known-good value, unless a newer value is
  /// already stored. Never throws: a storage failure here must not break the
  /// caller that just got a perfectly good network response.
  Future<void> save(Map<String, dynamic> json, {DateTime? at}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = (at ?? DateTime.now()).millisecondsSinceEpoch;
      final storedTimestamp = prefs.getInt(_atKey) ?? 0;
      if (timestamp < storedTimestamp) return;
      await prefs.setString(_dataKey, jsonEncode(json));
      await prefs.setInt(_atKey, timestamp);
    } catch (_) {
      // Best-effort cache: never break the caller over a storage failure.
    }
  }

  /// The last cached value, or `null` if nothing has been cached yet (or it
  /// could not be read back). Never throws.
  Future<Map<String, dynamic>?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_dataKey);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// When [read] would return something, the moment it was cached.
  Future<DateTime?> cachedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_atKey);
      return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }
}
