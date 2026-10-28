import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/services/device_identity_service.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/services/google_auth_service.dart';
import 'package:tuhfatul_muslim/features/auth/data/models/forgot_password_request_model.dart';
import 'package:tuhfatul_muslim/features/auth/data/models/google_sign_in_request_model.dart';
import 'package:tuhfatul_muslim/features/auth/data/models/login_request_model.dart';
import 'package:tuhfatul_muslim/features/auth/data/models/register_request_model.dart';
import 'package:tuhfatul_muslim/features/auth/data/models/resend_otp_request_model.dart';
import 'package:tuhfatul_muslim/features/auth/data/models/reset_password_request_model.dart';
import 'package:tuhfatul_muslim/features/auth/data/models/verify_otp_request_model.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/auth_user.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/google_sign_in_params.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/login_params.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/otp_verification_result.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/register_params.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/reset_password_params.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/verify_otp_params.dart';
import 'package:tuhfatul_muslim/features/auth/domain/repositories/account_repository.dart';

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
  Future<Either<Failure, AuthUser>> googleSignIn(
    GoogleSignInParams params,
  ) async {
    final result = await _googleSignIn(params);
    if (result.isLeft()) {
      // The ID token was spent on a request that failed, so drop the cached
      // Google session: retrying with the same stale credential would fail
      // the same way, and the user would be stuck until they reinstalled.
      await GoogleAuthService.instance.clearStaleSession();
    }
    return result;
  }

  Future<Either<Failure, AuthUser>> _googleSignIn(GoogleSignInParams params) {
    return _guard(() async {
      // Filled in here so every entry point (sign-in, sign-up, the guest
      // prompt) sends them without having to gather them itself. Values
      // already on [params] win, which is what tests use.
      final identity = await DeviceIdentityService.instance.describe();
      final result = await _remote.googleSignIn(
        GoogleSignInRequestModel.fromParams(
          GoogleSignInParams(
            idToken: params.idToken,
            email: params.email,
            displayName: params.displayName,
            photoUrl: params.photoUrl,
            fcmToken: params.fcmToken,
            deviceId: params.deviceId ?? identity.deviceId,
            appVersion: params.appVersion ?? identity.appVersion,
          ),
        ),
      );
      // Same Hive key as e-mail sign-in, so every protected call, the token
      // refresh and logout all keep working unchanged.
      await _local.cacheToken(result.token);
      final email = (params.email ?? '').trim();
      return result.user ??
          AuthUser(
            id: '',
            name: params.displayName?.trim().isNotEmpty == true
                ? params.displayName!.trim()
                : email.split('@').first,
            email: email,
          );
    });
  }

  @override
  Future<void> logout() async {
    await _local.clearToken();
    // Also drop the Google SDK's own cached account, so the next sign-in
    // shows the picker instead of silently reusing the last one. A no-op for
    // sessions that never used Google.
    await GoogleAuthService.instance.signOut();
  }

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
