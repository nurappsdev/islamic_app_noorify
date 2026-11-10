import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/profile/domain/repositories/profile_repository.dart';

/// Uploads a profile photo via `POST /s3/upload` and returns its public URL.
class UploadAvatar {
  const UploadAvatar(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, String>> call(File file) =>
      _repository.uploadAvatar(file);
}
