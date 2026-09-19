import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail.dart';

/// One page of `GET /hadiths?subCategoryId=...` / `?bookId=...` plus its pagination `meta`.
class HadithDetailPage {
  const HadithDetailPage({
    required this.hadiths,
    required this.page,
    required this.totalPage,
    required this.total,
  });

  final List<HadithDetail> hadiths;
  final int page;
  final int totalPage;
  final int total;

  bool get hasMore => page < totalPage;
}
