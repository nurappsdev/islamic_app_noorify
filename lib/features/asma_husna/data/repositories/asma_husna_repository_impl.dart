import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/asma_husna/data/datasources/asma_husna_local_data_source.dart';
import 'package:islami_app_noorify/features/asma_husna/data/datasources/asma_husna_remote_data_source.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name_detail.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/repositories/asma_husna_repository.dart';

class AsmaHusnaRepositoryImpl implements AsmaHusnaRepository {
  AsmaHusnaRepositoryImpl(this._remote, this._local);

  final AsmaHusnaRemoteDataSource _remote;
  final AsmaHusnaLocalDataSource _local;

  /// Cache-first: the 99 names (each with its full explanation) are fetched
  /// from `GET /asma-ul-husna` only the first time this ever succeeds, then
  /// served straight from [AsmaHusnaLocalDataSource] on every later call —
  /// across rebuilds, navigations, and app restarts — until that cache is
  /// missing or incomplete.
  @override
  Future<Either<Failure, List<AsmaName>>> getNames() async {
    final cached = await _local.getCachedNames();
    if (cached != null) return Right(cached);

    try {
      final remote = await _remote.getNames();
      await _local.cacheNames(remote);
      return Right(remote);
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

  /// Resolved from the same cache [getNames] fills — no per-id network call
  /// once the full list has been synced. Falls back to
  /// `GET /asma-ul-husna/{id}` only when [id] isn't cached yet (e.g. opened
  /// before the first sync has completed).
  @override
  Future<Either<Failure, AsmaNameDetail>> getNameDetail(String id) async {
    final cached = await _local.getCachedNames();
    if (cached != null) {
      for (final name in cached) {
        if (name.id == id) return Right(name.toDetail());
      }
    }

    try {
      return Right(await _remote.getNameDetail(id));
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
