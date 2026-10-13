import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/features/dua/data/dua_bookmark_model.dart';

export 'dua_bookmark_model.dart';

/// Hive-backed storage for the Dua "Saved" feature — folders and the duas
/// filed under them. A [ChangeNotifier] (not a `ValueNotifier<List<...>>`
/// like `CustomZikrStore`) because a folder can exist with zero duas in it,
/// so folder changes don't always coincide with a bookmark-list change.
class DuaBookmarkStore extends ChangeNotifier {
  DuaBookmarkStore._() {
    _items = _readItems();
    _folders = _readFolders();
  }

  static final instance = DuaBookmarkStore._();

  /// The folder every dua is saved under by default.
  static const defaultFolder = 'Favorite';

  static const _foldersKey = '__folders__';

  Box<dynamic> get _box => HiveService.duaBookmarks;

  List<DuaBookmarkModel> _items = const [];
  List<String> _folders = const [];

  /// Every saved dua (all folders), newest first.
  List<DuaBookmarkModel> get items => _items;

  /// Every folder — including ones created empty and never saved into.
  List<String> get folders => _folders;

  List<DuaBookmarkModel> _readItems() => [
    for (final key in _box.keys)
      if (key != _foldersKey) DuaBookmarkModel.fromMap(_box.get(key) as Map),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<String> _readFolders() {
    final stored = (_box.get(_foldersKey) as List?)?.cast<String>() ?? const [];
    final set = {
      defaultFolder,
      ...stored,
      for (final item in _items) item.folder,
    };
    return set.toList();
  }

  void _refresh() {
    _items = _readItems();
    _folders = _readFolders();
    notifyListeners();
  }

  int countIn(String folder) =>
      _items.where((item) => item.folder == folder).length;

  List<DuaBookmarkModel> itemsIn(String folder) =>
      _items.where((item) => item.folder == folder).toList();

  /// The folders [duaId] is currently saved under.
  Set<String> foldersFor(String duaId) => {
    for (final item in _items)
      if (item.duaId == duaId) item.folder,
  };

  void createFolder(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_folders.any((f) => f.toLowerCase() == trimmed.toLowerCase())) return;
    final stored = (_box.get(_foldersKey) as List?)?.cast<String>() ?? const [];
    _box.put(_foldersKey, [...stored, trimmed]);
    _refresh();
  }

  void renameFolder(String oldName, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName) return;
    final stored =
        ((_box.get(_foldersKey) as List?)?.cast<String>() ?? const []).toList();
    final index = stored.indexOf(oldName);
    if (index >= 0) {
      stored[index] = trimmed;
    } else {
      stored.add(trimmed);
    }
    _box.put(_foldersKey, stored);
    for (final key in _box.keys.toList()) {
      if (key == _foldersKey) continue;
      final map = Map<dynamic, dynamic>.from(_box.get(key) as Map);
      if (map['folder'] == oldName) {
        map['folder'] = trimmed;
        _box.put(key, map);
      }
    }
    _refresh();
  }

  void deleteFolder(String name) {
    final stored =
        ((_box.get(_foldersKey) as List?)?.cast<String>() ?? const [])
            .where((f) => f != name)
            .toList();
    _box.put(_foldersKey, stored);
    for (final key in _box.keys.toList()) {
      if (key == _foldersKey) continue;
      final map = _box.get(key) as Map;
      if (map['folder'] == name) _box.delete(key);
    }
    _refresh();
  }

  /// Files the dua under exactly [folders], replacing its prior membership.
  /// [build] is called once per newly-added folder to produce that entry's
  /// snapshot.
  void saveToFolders({
    required String duaId,
    required Set<String> folders,
    required DuaBookmarkModel Function(String folder) build,
  }) {
    final current = foldersFor(duaId);
    for (final folder in current.difference(folders)) {
      _box.delete(_keyOf(duaId, folder));
    }
    for (final folder in folders.difference(current)) {
      _box.put(_keyOf(duaId, folder), build(folder).toMap());
    }
    _refresh();
  }

  void removeFromFolder(String duaId, String folder) {
    _box.delete(_keyOf(duaId, folder));
    _refresh();
  }

  static String _keyOf(String duaId, String folder) => '$duaId::$folder';
}
