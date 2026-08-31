import 'package:shared_preferences/shared_preferences.dart';

/// Per-device store of bookmarked hadith, keyed by `"<book slug>#<hadith no>"`
/// in a single `SharedPreferences` string list.
class HadithBookmarkStore {
  HadithBookmarkStore._();

  factory HadithBookmarkStore() => _instance;

  static final HadithBookmarkStore _instance = HadithBookmarkStore._();

  static const _key = 'hadith_bookmarks';

  String _id(String slug, int hadithNo) => '$slug#$hadithNo';

  Future<List<String>> _read(SharedPreferences prefs) =>
      Future.value(prefs.getStringList(_key) ?? const <String>[]);

  Future<bool> isBookmarked(String slug, int hadithNo) async {
    final prefs = await SharedPreferences.getInstance();
    return (await _read(prefs)).contains(_id(slug, hadithNo));
  }

  /// Toggles the bookmark and returns the new state (`true` = now bookmarked).
  Future<bool> toggle(String slug, int hadithNo) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = (await _read(prefs)).toList();
    final id = _id(slug, hadithNo);
    final nowOn = !entries.contains(id);
    if (nowOn) {
      entries.add(id);
    } else {
      entries.remove(id);
    }
    await prefs.setStringList(_key, entries);
    return nowOn;
  }
}
