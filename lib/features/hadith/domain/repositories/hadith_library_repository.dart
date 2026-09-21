import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/ebook.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_last_read.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_progress.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_sub_category_page.dart';

abstract interface class HadithLibraryRepository {
  /// The hadith collections of the library (`GET /hadiths/books/lists`),
  /// in the server's display order.
  Future<Either<Failure, List<HadithLibraryBook>>> getBooks();

  /// The active e-books of the library (`GET /ebooks`), in the server's
  /// display order.
  Future<Either<Failure, List<Ebook>>> getEbooks();

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

  /// Reports the active reading time of a hadith (`POST
  /// /hadiths/reading/track`). [date] is `YYYY-MM-DD`.
  Future<Either<Failure, Unit>> trackReading({
    required String hadithId,
    required int seconds,
    required bool completed,
    required String date,
  });

  /// The reading progress overall and per category
  /// (`GET /hadiths/reading/progress/categories`, needs the login token).
  Future<Either<Failure, HadithReadingProgress>> getReadingProgress();

  /// The reading progress overall and per sub-category
  /// (`GET /hadiths/reading/progress/sub-categories`, needs the login token).
  Future<Either<Failure, HadithReadingProgress>>
  getSubCategoryReadingProgress();

  /// The hadith read most recently (`GET /hadiths/reading/last-read`, needs
  /// the login token); null when nothing has been read yet.
  Future<Either<Failure, HadithLastRead?>> getLastRead();

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
