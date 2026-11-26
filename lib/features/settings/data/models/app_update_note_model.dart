import 'package:tuhfatul_muslim/features/settings/domain/entities/app_update_note.dart';

/// Reads `GET /settings/new-updates`' `data`:
/// ```json
/// {
///   "title": "New Updates & Release Notes",
///   "version": "1.1.0",
///   "releaseDate": "2026-11-26",
///   "content": "Markdown text..."
/// }
/// ```
class AppUpdateNoteModel extends AppUpdateNote {
  const AppUpdateNoteModel({
    required super.title,
    required super.content,
    super.version,
    super.releaseDate,
  });

  factory AppUpdateNoteModel.fromJson(Map<String, dynamic> json) {
    return AppUpdateNoteModel(
      title: _text(json['title']) ?? '',
      content: _text(json['content']) ?? _text(json['body']) ?? '',
      version: _text(json['version']) ?? _text(json['appVersion']),
      releaseDate: _text(json['releaseDate']) ?? _text(json['publishedAt']),
    );
  }

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
