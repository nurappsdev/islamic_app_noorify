import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/alarm/data/datasources/ringtone_remote_data_source.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/ringtone.dart';
import 'package:islami_app_noorify/features/alarm/domain/repositories/ringtone_repository.dart';

class RingtoneRepositoryImpl implements RingtoneRepository {
  RingtoneRepositoryImpl([RingtoneRemoteDataSource? remote])
    : _remote = remote ?? RingtoneRemoteDataSourceImpl();

  final RingtoneRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Ringtone>>> getRingtones() async {
    try {
      return Right(await _remote.getRingtones());
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
