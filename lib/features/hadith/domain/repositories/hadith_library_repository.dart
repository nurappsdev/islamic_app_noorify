import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_sub_category_page.dart';

abstract interface class HadithLibraryRepository {
  /// The hadith collections of the library (`GET /hadiths/books/lists`),
  /// in the server's display order.
  Future<Either<Failure, List<HadithLibraryBook>>> getBooks();

  /// One page of the categories (chapters) of a collection
  /// (`GET /hadiths/categories?bookId=...&page=...&limit=...`), in display
  /// order.
  ///
  /// [searchTerm] filters by the category's Bangla, Arabic or English name.
  Future<Either<Failure, HadithCategoryPage>> getCategories(
    String bookId, {
    required int page,
    required int limit,
    String? searchTerm,
  });

  /// One page of a category's sub-categories
  /// (`GET /hadiths/categories/{categoryId}/subcategories`), in display
  /// order. [searchTerm] filters by name.
  Future<Either<Failure, HadithSubCategoryPage>> getSubCategories(
    String categoryId, {
    required int page,
    required int limit,
    String? searchTerm,
  });

  /// One page of the hadiths of a sub-category
  /// (`GET /hadiths?subCategoryId=...&page=...&limit=...`) or of a whole book
  /// (`...&bookId=...`), in display order. Pass one of [subCategoryId] /
  /// [bookId].
  Future<Either<Failure, HadithDetailPage>> getHadiths({
    String? subCategoryId,
    String? bookId,
    required int page,
    required int limit,
  });
}
