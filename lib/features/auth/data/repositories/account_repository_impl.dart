import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:islami_app_noorify/features/auth/data/models/forgot_password_request_model.dart';
import 'package:islami_app_noorify/features/auth/data/models/login_request_model.dart';
import 'package:islami_app_noorify/features/auth/data/models/register_request_model.dart';
import 'package:islami_app_noorify/features/auth/data/models/resend_otp_request_model.dart';
import 'package:islami_app_noorify/features/auth/data/models/reset_password_request_model.dart';
import 'package:islami_app_noorify/features/auth/data/models/verify_otp_request_model.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/auth_user.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/login_params.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/otp_verification_result.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/register_params.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/reset_password_params.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/verify_otp_params.dart';
import 'package:islami_app_noorify/features/auth/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._remote, {AuthLocalDataSource? local})
    : _local = local ?? AuthLocalDataSourceImpl();

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Either<Failure, AuthUser>> register(RegisterParams params) {
    return _guard(
      () => _remote.register(RegisterRequestModel.fromParams(params)),
    );
  }

  @override
  Future<Either<Failure, OtpVerificationResult>> verifyEmailOtp(
    VerifyOtpParams params,
  ) {
    return _guard<OtpVerificationResult>(() async {
      final result = await _remote.verifyEmail(
        VerifyOtpRequestModel.fromParams(params),
      );
      final token = result.accessToken;
      if (params.startSession && token != null) {
        // A verified new account is signed in straight away.
        await _local.cacheToken(token);
      }
      return result;
    });
  }

  @override
  Future<Either<Failure, String>> resendOtp(String email) {
    return _guard(() => _remote.resendOtp(ResendOtpRequestModel(email: email)));
  }

  @override
  Future<Either<Failure, String>> forgotPassword(String email) {
    return _guard(
      () => _remote.forgotPassword(ForgotPasswordRequestModel(email: email)),
    );
  }

  @override
  Future<Either<Failure, String>> resetPassword(ResetPasswordParams params) {
    return _guard(
      () => _remote.resetPassword(
        ResetPasswordRequestModel.fromParams(params),
        resetToken: params.resetToken,
      ),
    );
  }

  @override
  Future<Either<Failure, AuthUser>> login(LoginParams params) {
    return _guard(() async {
      final result = await _remote.login(LoginRequestModel.fromParams(params));
      // Persist the token to Hive so the session survives app restarts.
      await _local.cacheToken(result.token);
      return result.user ??
          AuthUser(
            id: '',
            name: params.email.split('@').first,
            email: params.email.trim(),
          );
    });
  }

  @override
  Future<void> logout() => _local.clearToken();

  @override
  String? get authToken => _local.getToken();

  @override
  bool get isSignedIn => _local.hasToken;

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
