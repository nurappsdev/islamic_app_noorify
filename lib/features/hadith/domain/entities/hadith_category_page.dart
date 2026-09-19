import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category.dart';

/// One page of `GET /hadiths/categories` plus its pagination `meta`.
class HadithCategoryPage {
  const HadithCategoryPage({
    required this.categories,
    required this.page,
    required this.totalPage,
    required this.total,
  });

  final List<HadithCategory> categories;
  final int page;
  final int totalPage;
  final int total;

  bool get hasMore => page < totalPage;
}
