import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/settings/domain/entities/app_update_note.dart';
import 'package:tuhfatul_muslim/features/settings/domain/repositories/settings_support_repository.dart';

/// Reads the current release notes (`GET /settings/new-updates`).
class GetNewUpdates {
  const GetNewUpdates(this._repository);

  final SettingsSupportRepository _repository;

  Future<Either<Failure, AppUpdateNote>> call() => _repository.getNewUpdates();
}
