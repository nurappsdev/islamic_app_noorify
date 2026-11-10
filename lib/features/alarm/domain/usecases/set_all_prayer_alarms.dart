import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/prayer_alarm_batch.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/repositories/alarm_repository.dart';

class SetAllPrayerAlarms {
  const SetAllPrayerAlarms(this._repository);

  final AlarmRepository _repository;

  Future<Either<Failure, void>> call(PrayerAlarmBatch batch) =>
      _repository.setAllPrayerAlarms(batch);
}
