import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_plan.dart';

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

class HadithPlanModel extends HadithPlan {
  const HadithPlanModel({
    required super.id,
    required super.name,
    required super.status,
    required super.totalHadiths,
    required super.completedHadiths,
    required super.percentage,
    required super.isCompleted,
    super.bookId,
    super.bookTitleEnglish,
    super.bookTitleBangla,
    super.categoryIds,
    super.targetDays,
  });

  /// [json] is one entry of `data`; the counts are under `counts`.
  factory HadithPlanModel.fromJson(Map<String, dynamic> json) {
    final counts = _map(json['counts']);
    final target = (json['targetDays'] as num?)?.toInt();
    // `bookId` may come populated (an object with `_id`, `sourceEnglish` and
    // `sourceBangla`) or as a plain id (then there's no title to show).
    final rawBookId = json['bookId'];
    final bookObject = rawBookId is Map<String, dynamic> ? rawBookId : null;
    final bookId = bookObject != null
        ? bookObject['_id']?.toString()
        : rawBookId?.toString();
    final rawCategoryIds = json['categoryIds'];
    return HadithPlanModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      targetDays: target != null && target > 0 ? target : null,
      bookId: bookId != null && bookId.isNotEmpty ? bookId : null,
      bookTitleEnglish: bookObject?['sourceEnglish']?.toString() ?? '',
      bookTitleBangla: bookObject?['sourceBangla']?.toString() ?? '',
      categoryIds: rawCategoryIds is List
          ? [
              for (final entry in rawCategoryIds)
                if (entry is Map<String, dynamic>)
                  entry['_id']?.toString() ?? ''
                else
                  entry?.toString() ?? '',
            ].where((id) => id.isNotEmpty).toList()
          : const [],
      totalHadiths: (counts['totalHadiths'] as num?)?.toInt() ?? 0,
      completedHadiths: (counts['completedHadiths'] as num?)?.toInt() ?? 0,
      percentage: ((counts['percentage'] as num?)?.toDouble() ?? 0)
          .clamp(0, 100)
          .toDouble(),
      isCompleted: counts['isCompleted'] == true,
    );
  }
}

class HadithPlanPageModel extends HadithPlanPage {
  const HadithPlanPageModel({
    required super.plans,
    required super.page,
    required super.totalPage,
    required super.total,
  });

  factory HadithPlanPageModel.fromJson(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> meta,
  ) {
    final plans = items.map(HadithPlanModel.fromJson).toList();
    return HadithPlanPageModel(
      plans: plans,
      page: (meta['page'] as num?)?.toInt() ?? 1,
      // Without `meta`, treat what we got as the only page.
      totalPage: (meta['totalPage'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? plans.length,
    );
  }
}
