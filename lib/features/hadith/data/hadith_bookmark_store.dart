import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A single bookmarked hadith.
class HadithBookmark {
  const HadithBookmark({
    required this.bookSlug,
    required this.hadithNo,
    required this.titleAr,
    required this.titleBn,
    required this.savedAt,
  });

  final String bookSlug;
  final int hadithNo;
  final String titleAr;
  final String titleBn;
  final DateTime savedAt;

  /// Identity of the bookmarked hadith (`"<book slug>#<hadith no>"`).
  String get key => '$bookSlug#$hadithNo';

  String get displayTitle => titleBn.isNotEmpty ? titleBn : titleAr;

  Map<String, dynamic> toJson() => {
    'bookSlug': bookSlug,
    'hadithNo': hadithNo,
    'titleAr': titleAr,
    'titleBn': titleBn,
    'savedAt': savedAt.toIso8601String(),
  };

  factory HadithBookmark.fromJson(Map<String, dynamic> json) => HadithBookmark(
    bookSlug: json['bookSlug'] as String? ?? '',
    hadithNo: (json['hadithNo'] as num?)?.toInt() ?? 0,
    titleAr: json['titleAr'] as String? ?? '',
    titleBn: json['titleBn'] as String? ?? '',
    savedAt:
        DateTime.tryParse(json['savedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// Per-device store of bookmarked hadith, kept as a JSON list in
/// `SharedPreferences` and ordered newest-saved first.
class HadithBookmarkStore {
  HadithBookmarkStore._();

  factory HadithBookmarkStore() => _instance;

  static final HadithBookmarkStore _instance = HadithBookmarkStore._();

  static const _key = 'hadith_bookmarks';

  Future<List<HadithBookmark>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final list = <HadithBookmark>[];
    for (final item in raw) {
      try {
        list.add(
          HadithBookmark.fromJson(jsonDecode(item) as Map<String, dynamic>),
        );
      } catch (_) {
        // Skip malformed entries.
      }
    }
    list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return list;
  }

  Future<bool> isBookmarked(String slug, int hadithNo) async {
    final id = '$slug#$hadithNo';
    return (await all()).any((b) => b.key == id);
  }

  Future<void> _write(List<HadithBookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, [
      for (final b in bookmarks) jsonEncode(b.toJson()),
    ]);
  }

  /// Adds [bookmark] if the hadith is not saved, otherwise removes it.
  /// Returns the new state (`true` = now bookmarked).
  Future<bool> toggle(HadithBookmark bookmark) async {
    final current = await all();
    final exists = current.any((b) => b.key == bookmark.key);
    await _write(
      exists
          ? current.where((b) => b.key != bookmark.key).toList()
          : [bookmark, ...current],
    );
    return !exists;
  }

  Future<void> remove(String slug, int hadithNo) async {
    final id = '$slug#$hadithNo';
    await _write((await all()).where((b) => b.key != id).toList());
  }
}
