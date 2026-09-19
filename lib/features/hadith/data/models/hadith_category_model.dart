import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category.dart';

class HadithCategoryModel extends HadithCategory {
  const HadithCategoryModel({
    required super.id,
    required super.bookId,
    required super.name,
    required super.nameBangla,
    required super.nameArabic,
    required super.sectionNumber,
    required super.displayOrder,
    required super.totalHadiths,
    required super.totalSubCategories,
  });

  factory HadithCategoryModel.fromJson(Map<String, dynamic> json) =>
      HadithCategoryModel(
        id: (json['_id'] ?? json['id'])?.toString() ?? '',
        bookId: json['bookId']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        nameBangla: json['nameBangla'] as String? ?? '',
        nameArabic: json['nameArabic'] as String? ?? '',
        sectionNumber: (json['sectionNumber'] as num?)?.toInt() ?? 0,
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
        totalHadiths: (json['totalHadiths'] as num?)?.toInt() ?? 0,
        totalSubCategories: (json['totalSubCategories'] as num?)?.toInt() ?? 0,
      );
}
