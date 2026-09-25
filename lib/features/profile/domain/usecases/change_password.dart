import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/profile/domain/repositories/change_password_repository.dart';

class ChangePassword {
  const ChangePassword(this._repository);

  final ChangePasswordRepository _repository;

  Future<Either<Failure, String>> call({
    required String oldPassword,
    required String newPassword,
  }) => _repository.changePassword(
    oldPassword: oldPassword,
    newPassword: newPassword,
  );
}
