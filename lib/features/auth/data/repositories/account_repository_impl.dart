import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:islami_app_noorify/features/auth/data/models/register_request_model.dart';
import 'package:islami_app_noorify/features/auth/data/models/verify_otp_request_model.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/auth_user.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/register_params.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/verify_otp_params.dart';
import 'package:islami_app_noorify/features/auth/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<Either<Failure, AuthUser>> register(RegisterParams params) {
    return _guard(() async {
      final user = await _remote.register(
        RegisterRequestModel.fromParams(params),
      );
      return user;
    });
  }

  @override
  Future<Either<Failure, String>> verifyEmailOtp(VerifyOtpParams params) {
    return _guard(() {
      return _remote.verifyEmail(VerifyOtpRequestModel.fromParams(params));
    });
  }

  /// Runs [action], mapping any data-layer exception to a typed [Failure].
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
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
