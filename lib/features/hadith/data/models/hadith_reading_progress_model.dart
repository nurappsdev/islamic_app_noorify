import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_progress.dart';

double _percentage(Object? value) =>
    ((value as num?)?.toDouble() ?? 0).clamp(0, 100).toDouble();

class HadithCategoryProgressModel extends HadithCategoryProgress {
  const HadithCategoryProgressModel({
    required super.id,
    required super.bookId,
    required super.totalHadiths,
    required super.readHadiths,
    required super.percentage,
  });

  factory HadithCategoryProgressModel.fromJson(Map<String, dynamic> json) =>
      HadithCategoryProgressModel(
        id: (json['id'] ?? json['_id'])?.toString() ?? '',
        bookId: json['bookId']?.toString() ?? '',
        totalHadiths: (json['totalHadiths'] as num?)?.toInt() ?? 0,
        readHadiths: (json['readHadiths'] as num?)?.toInt() ?? 0,
        percentage: _percentage(json['percentage']),
      );
}

class HadithReadingProgressModel extends HadithReadingProgress {
  const HadithReadingProgressModel({
    required super.summary,
    required super.byId,
  });

  /// [data] is the envelope's `data`: `{summary: {...}, data: [...]}`.
  factory HadithReadingProgressModel.fromJson(Map<String, dynamic> data) {
    final summary = data['summary'];
    final summaryJson = summary is Map<String, dynamic>
        ? summary
        : const <String, dynamic>{};
    final items = data['data'];
    return HadithReadingProgressModel(
      summary: HadithReadingSummary(
        totalHadiths: (summaryJson['totalHadiths'] as num?)?.toInt() ?? 0,
        readHadiths: (summaryJson['readHadiths'] as num?)?.toInt() ?? 0,
        percentage: _percentage(summaryJson['percentage']),
        completedGroups: (summaryJson['completedGroups'] as num?)?.toInt() ?? 0,
      ),
      byId: {
        if (items is List)
          for (final item in items.whereType<Map<String, dynamic>>())
            if (HadithCategoryProgressModel.fromJson(item) case final p
                when p.id.isNotEmpty)
              p.id: p,
      },
    );
  }
}
