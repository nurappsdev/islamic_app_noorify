import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_category.dart';

/// Reads a JSON number that may arrive as a num or a numeric string.
num? readNum(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

/// Reads a JSON map, or `null` for anything else.
Map<String, dynamic>? readMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

/// Reads a non-empty string id, or `null`.
String? readId(Object? value) {
  final text = value?.toString();
  return (text == null || text.isEmpty) ? null : text;
}

class QuizCategoryModel extends QuizCategory {
  const QuizCategoryModel({
    required super.id,
    required super.name,
    required super.description,
    required super.iconUrl,
    required super.displayOrder,
    required super.totalQuestions,
    required super.isActive,
  });

  /// Lenient: an attempt row may carry only `{id}` for a category that was
  /// not populated, so every other field falls back to an empty value.
  factory QuizCategoryModel.fromJson(Map<String, dynamic> json) {
    final iconUrl = json['iconUrl']?.toString().trim();
    return QuizCategoryModel(
      id: readId(json['id']) ?? '',
      name: LocalizedText.fromJson(json['name']),
      description: LocalizedText.fromJson(json['description']),
      iconUrl: (iconUrl == null || iconUrl.isEmpty) ? null : iconUrl,
      displayOrder: readNum(json['displayOrder'])?.toInt() ?? 0,
      totalQuestions: _readCount(json['totalQuestions']),
      isActive: json['isActive'] != false,
    );
  }

  /// `{value, bn, en}`, or a bare number from an older payload.
  static LocalizedCount _readCount(Object? json) {
    final map = readMap(json);
    if (map != null) {
      final value = readNum(map['value'])?.toInt() ?? 0;
      final text = LocalizedText.fromJson(map);
      return LocalizedCount(
        value: value,
        text: text.isEmpty ? LocalizedText(bn: '$value', en: '$value') : text,
      );
    }
    final value = readNum(json)?.toInt() ?? 0;
    return LocalizedCount(
      value: value,
      text: LocalizedText(bn: '$value', en: '$value'),
    );
  }
}
