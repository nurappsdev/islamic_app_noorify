import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/repositories/alarm_repository.dart';

class GetPrayerAlarms {
  const GetPrayerAlarms(this._repository);

  final AlarmRepository _repository;

  Future<Either<Failure, List<PrayerAlarm>>> call() =>
      _repository.getPrayerAlarms();
}
