import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/profile/data/datasources/delete_account_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/profile/domain/repositories/delete_account_repository.dart';

class DeleteAccountRepositoryImpl implements DeleteAccountRepository {
  DeleteAccountRepositoryImpl(this._remote);

  final DeleteAccountRemoteDataSource _remote;

  @override
  Future<Either<Failure, String>> deleteAccount() async {
    try {
      final message = await _remote.deleteAccount();
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
