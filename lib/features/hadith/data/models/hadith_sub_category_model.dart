import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_sub_category.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_sub_category_page.dart';

class HadithSubCategoryModel extends HadithSubCategory {
  const HadithSubCategoryModel({
    required super.id,
    required super.categoryId,
    required super.name,
    required super.nameBangla,
    required super.nameEnglish,
    required super.nameArabic,
    required super.chapterNumber,
    required super.displayOrder,
    required super.totalHadiths,
  });

  factory HadithSubCategoryModel.fromJson(Map<String, dynamic> json) =>
      HadithSubCategoryModel(
        id: (json['_id'] ?? json['id'])?.toString() ?? '',
        categoryId: json['categoryId']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        nameBangla: json['nameBangla'] as String? ?? '',
        nameEnglish: json['nameEnglish'] as String? ?? '',
        nameArabic: json['nameArabic'] as String? ?? '',
        chapterNumber: (json['chapterNumber'] as num?)?.toInt() ?? 0,
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
        totalHadiths: (json['totalHadiths'] as num?)?.toInt() ?? 0,
      );
}

class HadithSubCategoryPageModel extends HadithSubCategoryPage {
  const HadithSubCategoryPageModel({
    required super.subCategories,
    required super.page,
    required super.totalPage,
    required super.total,
  });

  factory HadithSubCategoryPageModel.fromJson(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> meta,
  ) {
    final subCategories = items.map(HadithSubCategoryModel.fromJson).toList();
    return HadithSubCategoryPageModel(
      subCategories: subCategories,
      page: (meta['page'] as num?)?.toInt() ?? 1,
      // Without `meta`, treat what we got as the only page.
      totalPage: (meta['totalPage'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? subCategories.length,
    );
  }
}
