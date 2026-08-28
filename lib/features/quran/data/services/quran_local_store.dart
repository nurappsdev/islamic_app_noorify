import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:islami_app_noorify/features/quran/domain/bookmark.dart';
import 'package:islami_app_noorify/features/quran/domain/reading_history_entry.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

class QuranLocalStore {
  QuranLocalStore(this._preferences);

  static const _lastReadKey = 'quran_last_read';
  static const _historyKey = 'quran_reading_history';
  static const _bookmarksKey = 'quran_bookmarks';
  static const _translationLangKey = 'quran_translation_lang';
  static const _fontSizeKey = 'quran_font_size_multiplier';
  static const _maxHistory = 50;

  final SharedPreferences _preferences;

  static Future<QuranLocalStore> create() async {
    return QuranLocalStore(await SharedPreferences.getInstance());
  }

  Future<void> recordSurahOpened({
    required int surahNo,
    required String surahName,
    int ayahNo = 1,
  }) async {
    final entry = ReadingHistoryEntry(
      surahNo: surahNo,
      ayahNo: ayahNo,
      surahName: surahName,
      readAt: DateTime.now(),
    );
    await _preferences.setString(_lastReadKey, jsonEncode(entry.toJson()));

    final entries = await history();
    entries.removeWhere(
      (e) => e.surahNo == surahNo && e.ayahNo == ayahNo,
    );
    entries.insert(0, entry);
    final capped = entries.take(_maxHistory).toList();
    await _preferences.setString(
      _historyKey,
      jsonEncode(capped.map((e) => e.toJson()).toList()),
    );
  }

  Future<ReadingHistoryEntry?> lastRead() async {
    final raw = _preferences.getString(_lastReadKey);
    if (raw == null) return null;
    try {
      return ReadingHistoryEntry.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<ReadingHistoryEntry>> history() async {
    final raw = _preferences.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final item in list)
          ReadingHistoryEntry.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<List<Bookmark>> bookmarks() async {
    final raw = _preferences.getString(_bookmarksKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final item in list)
          Bookmark.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<bool> isBookmarked(int surahNo, int ayahNo) async {
    final marks = await bookmarks();
    return marks.any((b) => b.surahNo == surahNo && b.ayahNo == ayahNo);
  }

  Future<void> toggleBookmark({
    required int surahNo,
    required int ayahNo,
    required String surahName,
    required String snippet,
  }) async {
    final marks = await bookmarks();
    final existingIndex = marks.indexWhere(
      (b) => b.surahNo == surahNo && b.ayahNo == ayahNo,
    );
    if (existingIndex >= 0) {
      marks.removeAt(existingIndex);
    } else {
      marks.insert(
        0,
        Bookmark(
          surahNo: surahNo,
          ayahNo: ayahNo,
          surahName: surahName,
          snippet: snippet,
          savedAt: DateTime.now(),
        ),
      );
    }
    await _preferences.setString(
      _bookmarksKey,
      jsonEncode(marks.map((b) => b.toJson()).toList()),
    );
  }

  Future<void> removeBookmark(int surahNo, int ayahNo) async {
    final marks = await bookmarks();
    marks.removeWhere((b) => b.surahNo == surahNo && b.ayahNo == ayahNo);
    await _preferences.setString(
      _bookmarksKey,
      jsonEncode(marks.map((b) => b.toJson()).toList()),
    );
  }

  /// Translation language chosen for the Quran reader, independent of the app
  /// UI language. Null until the user has picked one.
  AppLanguage? translationLanguage() {
    final raw = _preferences.getString(_translationLangKey);
    for (final lang in AppLanguage.values) {
      if (lang.name == raw) return lang;
    }
    return null;
  }

  Future<void> setTranslationLanguage(AppLanguage lang) async {
    await _preferences.setString(_translationLangKey, lang.name);
  }

  double fontSizeMultiplier() {
    return _preferences.getDouble(_fontSizeKey) ?? 1.0;
  }

  Future<void> setFontSizeMultiplier(double multiplier) async {
    await _preferences.setDouble(_fontSizeKey, multiplier);
  }
}
