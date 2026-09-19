import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';

abstract interface class HadithLibraryRepository {
  /// The hadith collections of the library (`GET /hadiths/books/lists`),
  /// in the server's display order.
  Future<Either<Failure, List<HadithLibraryBook>>> getBooks();
}
