import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';

/// Contract for permanently deleting the signed-in user's backend account
/// record.
abstract interface class DeleteAccountRepository {
  /// Calls `DELETE /auth/delete-account`. Returns [Right] with the server's
  /// success message, or [Left] with a typed [Failure].
  Future<Either<Failure, String>> deleteAccount();
}
