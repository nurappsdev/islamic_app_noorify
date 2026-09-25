import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';

/// Contract for changing the signed-in user's password.
abstract interface class ChangePasswordRepository {
  /// Calls `/settings/change-password`. Returns [Right] with the server's
  /// success message, or [Left] with a typed [Failure].
  Future<Either<Failure, String>> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}
