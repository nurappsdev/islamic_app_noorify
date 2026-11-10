import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/repositories/alarm_repository.dart';

class SetPrayerAlarmEnabled {
  const SetPrayerAlarmEnabled(this._repository);

  final AlarmRepository _repository;

  Future<Either<Failure, void>> call({
    required String prayerType,
    required bool enabled,
  }) => _repository.setPrayerAlarmEnabled(
    prayerType: prayerType,
    enabled: enabled,
  );
}
