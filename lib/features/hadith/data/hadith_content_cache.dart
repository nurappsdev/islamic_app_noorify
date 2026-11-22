import 'dart:convert';

import 'package:tuhfatul_muslim/core/services/api_constants.dart';

import 'hadith_database.dart';

/// Offline-first storage for the Hadith library's static content (books,
/// e-books, categories, sub-categories and hadith pages), so they open from
/// the device instead of waiting for the API.
///
/// Entries are keyed by request, stored in [HadithDatabase] (kept across app
/// restarts and sign-out) and tagged with [contentVersion]: bump it when the
/// server's content changes shape, and old copies are dropped. Storage
/// failures only mean a cache miss; they never break loading.
class HadithContentCache {
  HadithContentCache({HadithDatabase? database})
    : _database = database ?? HadithDatabase();

  static final shared = HadithContentCache();

  /// Version of the cached content's format. Bumped to 2 when the API host
  /// became part of [keyOf]'s key: the host-less rows are dropped rather
  /// than left to answer for whichever environment is now configured.
  static const contentVersion = 2;

  /// Stored content older than this is refreshed in the background.
  static const refreshAfter = Duration(days: 1);

  final HadithDatabase _database;
  final _memory = <String, ({Map<String, dynamic> json, DateTime at})>{};
  bool _cleaned = false;

  /// The key [path] and [query] are stored under, scoped to the API host.
  ///
  /// The base URL is part of it because a build may point at production,
  /// staging or a dev host (`API_BASE_URL`): without it, content stored from
  /// one host is served for another, and a book that only exists on the new
  /// host never appears.
  static String keyOf(String path, Map<String, dynamic> query) {
    final keys = query.keys.toList()..sort();
    final params = [for (final k in keys) '$k=${query[k]}'].join('&');
    return '${ApiConstants.baseUrl}$path?$params';
  }

  /// The stored response and when it was stored, or null.
  Future<({Map<String, dynamic> json, DateTime at})?> read(String key) async {
    final hit = _memory[key];
    if (hit != null) return hit;
    try {
      if (!_cleaned) {
        _cleaned = true;
        await _database.dropStaleContent(contentVersion);
      }
      final row = await _database.cachedContent(key, contentVersion);
      if (row == null) return null;
      final json = jsonDecode(row.body);
      if (json is! Map<String, dynamic>) return null;
      return _memory[key] = (json: json, at: row.cachedAt);
    } catch (_) {
      return null;
    }
  }

  /// Stores [json] for [key]; true when it reached the device's storage.
  /// The memory copy is only kept alongside a stored one.
  Future<bool> write(String key, Map<String, dynamic> json) async {
    try {
      await _database.cacheContent(key, jsonEncode(json), contentVersion);
    } catch (_) {
      return false;
    }
    _memory[key] = (json: json, at: DateTime.now());
    return true;
  }

  static bool isStale(DateTime at) =>
      DateTime.now().difference(at) > refreshAfter;
}
