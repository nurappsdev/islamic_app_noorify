import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/repositories/alarm_repository.dart';

class GetAlarms {
  const GetAlarms(this._repository);

  final AlarmRepository _repository;

  Future<Either<Failure, List<AlarmEntry>>> call() => _repository.getAlarms();
}
