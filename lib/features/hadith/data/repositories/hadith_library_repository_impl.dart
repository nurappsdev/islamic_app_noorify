import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/ebook.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_last_read.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_comparison.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_progress.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_sub_category_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

class HadithLibraryRepositoryImpl implements HadithLibraryRepository {
  HadithLibraryRepositoryImpl(this._remote);

  final HadithLibraryRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<HadithLibraryBook>>> getBooks() async {
    try {
      final books = await _remote.getBooks();
      return Right(
        [...books]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<Ebook>>> getEbooks() async {
    try {
      final ebooks = await _remote.getEbooks();
      return Right(
        ebooks.where((e) => e.isActive).toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, HadithCategoryPage>> getCategories(
    String bookId, {
    required int page,
    required int limit,
    String? searchTerm,
  }) async {
    try {
      return Right(
        await _remote.getCategories(
          bookId,
          page: page,
          limit: limit,
          searchTerm: searchTerm,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, HadithSubCategoryPage>> getSubCategories(
    String categoryId, {
    required int page,
    required int limit,
    String? searchTerm,
  }) async {
    try {
      return Right(
        await _remote.getSubCategories(
          categoryId,
          page: page,
          limit: limit,
          searchTerm: searchTerm,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> trackReading({
    required String hadithId,
    required int seconds,
    required bool completed,
    required String date,
  }) async {
    try {
      await _remote.trackReading(
        hadithId: hadithId,
        seconds: seconds,
        completed: completed,
        date: date,
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, HadithReadingProgress>> getReadingProgress() async {
    try {
      return Right(await _remote.getReadingProgress());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, HadithReadingProgress>>
  getSubCategoryReadingProgress() async {
    try {
      return Right(await _remote.getSubCategoryReadingProgress());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, HadithReadingHistory>> getReadingHistory({
    required String from,
    required String to,
  }) async {
    try {
      return Right(await _remote.getReadingHistory(from: from, to: to));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, HadithReadingComparison>> getReadingComparison({
    required String from,
    required String to,
  }) async {
    try {
      return Right(await _remote.getReadingComparison(from: from, to: to));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, HadithLastRead?>> getLastRead() async {
    try {
      return Right(await _remote.getLastRead());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, HadithDetailPage>> getHadiths({
    String? subCategoryId,
    String? bookId,
    required int page,
    required int limit,
  }) async {
    try {
      return Right(
        await _remote.getHadiths(
          subCategoryId: subCategoryId,
          bookId: bookId,
          page: page,
          limit: limit,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
