import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';
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
