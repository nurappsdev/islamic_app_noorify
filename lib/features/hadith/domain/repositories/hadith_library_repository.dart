import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';

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
}
