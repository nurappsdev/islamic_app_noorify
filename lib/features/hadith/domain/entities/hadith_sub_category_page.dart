import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_sub_category.dart';

/// One page of `GET /hadiths/categories/{id}/subcategories` plus its
/// pagination `meta`.
class HadithSubCategoryPage {
  const HadithSubCategoryPage({
    required this.subCategories,
    required this.page,
    required this.totalPage,
    required this.total,
  });

  final List<HadithSubCategory> subCategories;
  final int page;
  final int totalPage;
  final int total;

  bool get hasMore => page < totalPage;
}
