import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/settings/domain/entities/support_overview.dart';
import 'package:tuhfatul_muslim/features/settings/domain/repositories/settings_support_repository.dart';

/// Reads the support contact details (`GET /settings/overview`).
class GetSupportOverview {
  const GetSupportOverview(this._repository);

  final SettingsSupportRepository _repository;

  Future<Either<Failure, SupportOverview>> call() => _repository.getOverview();
}
