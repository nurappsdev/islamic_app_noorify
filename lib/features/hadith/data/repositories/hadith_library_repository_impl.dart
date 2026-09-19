import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';
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
}
