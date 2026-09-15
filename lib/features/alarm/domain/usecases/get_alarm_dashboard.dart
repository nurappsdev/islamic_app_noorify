import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_dashboard.dart';
import 'package:islami_app_noorify/features/alarm/domain/repositories/alarm_repository.dart';

class GetAlarmDashboard {
  const GetAlarmDashboard(this._repository);

  final AlarmRepository _repository;

  Future<Either<Failure, AlarmDashboard>> call() =>
      _repository.getAlarmDashboard();
}
