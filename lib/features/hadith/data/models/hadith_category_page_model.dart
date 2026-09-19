import 'package:islami_app_noorify/features/hadith/data/models/hadith_category_model.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category_page.dart';

class HadithCategoryPageModel extends HadithCategoryPage {
  const HadithCategoryPageModel({
    required super.categories,
    required super.page,
    required super.totalPage,
    required super.total,
  });

  factory HadithCategoryPageModel.fromJson(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> meta,
  ) {
    final categories = items.map(HadithCategoryModel.fromJson).toList();
    return HadithCategoryPageModel(
      categories: categories,
      page: (meta['page'] as num?)?.toInt() ?? 1,
      // Without `meta`, treat what we got as the only page.
      totalPage: (meta['totalPage'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? categories.length,
    );
  }
}
