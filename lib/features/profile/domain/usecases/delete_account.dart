import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/profile/domain/repositories/delete_account_repository.dart';

/// Permanently deletes the signed-in user's backend account record.
class DeleteAccount {
  const DeleteAccount(this._repository);

  final DeleteAccountRepository _repository;

  Future<Either<Failure, String>> call() => _repository.deleteAccount();
}
