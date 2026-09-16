import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/asma_husna/data/datasources/asma_husna_remote_data_source.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/repositories/asma_husna_repository.dart';

class AsmaHusnaRepositoryImpl implements AsmaHusnaRepository {
  AsmaHusnaRepositoryImpl(this._remote);

  final AsmaHusnaRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<AsmaName>>> getNames() async {
    try {
      return Right(await _remote.getNames());
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
