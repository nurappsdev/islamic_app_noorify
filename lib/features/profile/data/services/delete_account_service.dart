import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/storage/session_cleaner.dart';
import 'package:tuhfatul_muslim/features/alarm/data/services/alarm_scheduler.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/services/auth_service.dart';
import 'package:tuhfatul_muslim/features/profile/data/datasources/delete_account_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/profile/data/repositories/delete_account_repository_impl.dart';
import 'package:tuhfatul_muslim/features/profile/domain/usecases/delete_account.dart';

/// The entered password was rejected by whichever auth system backs the
/// current session, so the UI can show one fixed message regardless of
/// which path rejected it.
class IncorrectPasswordException implements Exception {
  const IncorrectPasswordException();
}

/// Orchestrates the Delete Account flow for the Settings screen.
///
/// This app has two independent sign-in paths: email/password accounts go
/// through its own REST backend (token cached in Hive) and never get a
/// Firebase user, while Google sign-in goes through Firebase (see
/// [AuthService]) and never has a REST token. Password verification below
/// branches on which one is active for the current session: `POST
/// /auth/delete-account` for a REST session, Firebase reauthentication
/// otherwise. The actual deletion (`DELETE /delete/me`) only runs after that
/// verification succeeds.
class DeleteAccountService {
  DeleteAccountService._();

  static final DeleteAccountService instance = DeleteAccountService._();

  final AuthLocalDataSource _local = AuthLocalDataSourceImpl();
  final AuthRemoteDataSource _authRemote = AuthRemoteDataSourceImpl();
  late final DeleteAccount _deleteAccount = DeleteAccount(
    DeleteAccountRepositoryImpl(DeleteAccountRemoteDataSourceImpl()),
  );

  /// Verifies [password] without changing the stored session. Returns
  /// `Right(null)` on success, or `Left` with [IncorrectPasswordException]
  /// for a rejected password, a [Failure] for a network/unknown problem, or
  /// a [FirebaseAuthException] for any other Firebase-side error (e.g.
  /// `too-many-requests`).
  Future<Either<Object, void>> verifyPassword(String password) async {
    final token = _local.getToken();
    if (token != null) {
      try {
        await _authRemote.verifyDeleteAccountPassword(
          password,
          authToken: token,
        );
        return const Right(null);
      } on ServerException {
        // POST /auth/delete-account failing for the signed-in session means
        // the password was wrong.
        return const Left(IncorrectPasswordException());
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (_) {
        return const Left(UnknownFailure());
      }
    }

    final user = AuthService.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      return const Left(UnknownFailure());
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      const wrongPasswordCodes = {
        'wrong-password',
        'invalid-credential',
        'user-mismatch',
      };
      if (wrongPasswordCodes.contains(e.code)) {
        return const Left(IncorrectPasswordException());
      }
      return Left(e);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  /// Deletes the backend account record, the Firebase user (if any), local
  /// session data, and cancels scheduled alarms. Only returns `Right(null)`
  /// once every step succeeds; on any failure nothing local is cleared, so
  /// the caller must not sign the user out.
  Future<Either<Object, void>> deleteAccount() async {
    final backendResult = await _deleteAccount();
    final backendFailure = backendResult.fold<Failure?>((f) => f, (_) => null);
    if (backendFailure != null) return Left(backendFailure);

    try {
      // No-op when the session has no Firebase user (a REST-only account).
      await AuthService.instance.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(UnknownFailure());
    }

    await SessionCleaner.clearUserData();
    await AlarmScheduler.cancelAllAlarms(reason: 'account_deleted');
    return const Right(null);
  }
}
