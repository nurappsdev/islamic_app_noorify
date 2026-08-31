import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A single bookmarked hadith and the folders it belongs to.
class HadithBookmark {
  const HadithBookmark({
    required this.bookSlug,
    required this.hadithNo,
    required this.titleAr,
    required this.titleBn,
    required this.savedAt,
    this.folders = const [HadithBookmarkStore.defaultFolder],
  });

  final String bookSlug;
  final int hadithNo;
  final String titleAr;
  final String titleBn;
  final DateTime savedAt;
  final List<String> folders;

  /// Identity of the bookmarked hadith (`"<book slug>#<hadith no>"`).
  String get key => '$bookSlug#$hadithNo';

  String get displayTitle => titleBn.isNotEmpty ? titleBn : titleAr;

  HadithBookmark copyWith({List<String>? folders, DateTime? savedAt}) =>
      HadithBookmark(
        bookSlug: bookSlug,
        hadithNo: hadithNo,
        titleAr: titleAr,
        titleBn: titleBn,
        savedAt: savedAt ?? this.savedAt,
        folders: folders ?? this.folders,
      );

  Map<String, dynamic> toJson() => {
    'bookSlug': bookSlug,
    'hadithNo': hadithNo,
    'titleAr': titleAr,
    'titleBn': titleBn,
    'savedAt': savedAt.toIso8601String(),
    'folders': folders,
  };

  factory HadithBookmark.fromJson(Map<String, dynamic> json) {
    final rawFolders = json['folders'];
    return HadithBookmark(
      bookSlug: json['bookSlug'] as String? ?? '',
      hadithNo: (json['hadithNo'] as num?)?.toInt() ?? 0,
      titleAr: json['titleAr'] as String? ?? '',
      titleBn: json['titleBn'] as String? ?? '',
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      folders: rawFolders is List && rawFolders.isNotEmpty
          ? rawFolders.map((e) => '$e').toList()
          : const [HadithBookmarkStore.defaultFolder],
    );
  }
}

/// Per-device store of bookmarked hadith (a JSON list, newest-saved first) plus
/// the set of user folders they can be filed under.
class HadithBookmarkStore {
  HadithBookmarkStore._();

  factory HadithBookmarkStore() => _instance;

  static final HadithBookmarkStore _instance = HadithBookmarkStore._();

  static const defaultFolder = 'Favorite';

  static const _key = 'hadith_bookmarks';
  static const _foldersKey = 'hadith_bookmark_folders';

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

  /// Every folder name: the default, any the user created, and any still
  /// referenced by a bookmark. Ordered with the default first.
  Future<List<String>> folders() async {
    final prefs = await SharedPreferences.getInstance();
    final names = <String>{
      defaultFolder,
      ...?prefs.getStringList(_foldersKey),
      for (final b in await all()) ...b.folders,
    };
    final ordered = names.toList()
      ..remove(defaultFolder)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return [defaultFolder, ...ordered];
  }

  Future<void> createFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == defaultFolder) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_foldersKey) ?? const <String>[];
    if (current.any((f) => f.toLowerCase() == trimmed.toLowerCase())) return;
    await prefs.setStringList(_foldersKey, [...current, trimmed]);
  }

  Future<bool> isBookmarked(String slug, int hadithNo) async {
    final id = '$slug#$hadithNo';
    return (await all()).any((b) => b.key == id);
  }

  /// Folders the given hadith is currently filed under (empty if not saved).
  Future<Set<String>> foldersFor(String slug, int hadithNo) async {
    final id = '$slug#$hadithNo';
    for (final b in await all()) {
      if (b.key == id) return b.folders.toSet();
    }
    return <String>{};
  }

  /// Number of saved hadith in each folder.
  Future<Map<String, int>> folderCounts() async {
    final counts = <String, int>{};
    for (final b in await all()) {
      for (final folder in b.folders) {
        counts[folder] = (counts[folder] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<void> _write(List<HadithBookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, [
      for (final b in bookmarks) jsonEncode(b.toJson()),
    ]);
  }

  /// Quick toggle used by the per-hadith icon: adds to the default folder if
  /// not saved, otherwise removes entirely. Returns the new state.
  Future<bool> toggle(HadithBookmark bookmark) async {
    final current = await all();
    final exists = current.any((b) => b.key == bookmark.key);
    await _write(
      exists
          ? current.where((b) => b.key != bookmark.key).toList()
          : [
              bookmark.copyWith(folders: const [defaultFolder]),
              ...current,
            ],
    );
    return !exists;
  }

  /// Files [bookmark] under exactly [folders]. An empty set removes it.
  Future<void> saveToFolders(
    HadithBookmark bookmark,
    Set<String> folders,
  ) async {
    final current = await all();
    final existing = current.where((b) => b.key == bookmark.key).firstOrNull;
    final rest = current.where((b) => b.key != bookmark.key).toList();
    if (folders.isEmpty) {
      await _write(rest);
      return;
    }
    final entry = (existing ?? bookmark).copyWith(
      folders: folders.toList(),
      savedAt: existing?.savedAt ?? DateTime.now(),
    );
    await _write([entry, ...rest]);
  }

  Future<void> remove(String slug, int hadithNo) async {
    final id = '$slug#$hadithNo';
    await _write((await all()).where((b) => b.key != id).toList());
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
