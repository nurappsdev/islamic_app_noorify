import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/alarm/domain/repositories/alarm_repository.dart';

class SetAlarmEnabled {
  const SetAlarmEnabled(this._repository);

  final AlarmRepository _repository;

  Future<Either<Failure, void>> call({
    required String id,
    required bool enabled,
  }) => _repository.setAlarmEnabled(id: id, enabled: enabled);
}
