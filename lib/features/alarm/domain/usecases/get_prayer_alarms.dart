import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:islami_app_noorify/features/alarm/domain/repositories/alarm_repository.dart';

class GetPrayerAlarms {
  const GetPrayerAlarms(this._repository);

  final AlarmRepository _repository;

  Future<Either<Failure, List<PrayerAlarm>>> call() =>
      _repository.getPrayerAlarms();
}
