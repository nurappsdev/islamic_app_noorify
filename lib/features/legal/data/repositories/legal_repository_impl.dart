import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/legal/data/datasources/legal_remote_data_source.dart';
import 'package:islami_app_noorify/features/legal/domain/entities/legal_document.dart';
import 'package:islami_app_noorify/features/legal/domain/repositories/legal_repository.dart';

class LegalRepositoryImpl implements LegalRepository {
  LegalRepositoryImpl(this._remote);

  final LegalRemoteDataSource _remote;

  @override
  Future<Either<Failure, LegalDocument>> getDocument(
    LegalDocumentType type,
  ) async {
    try {
      return Right(await _remote.getDocument(type));
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
