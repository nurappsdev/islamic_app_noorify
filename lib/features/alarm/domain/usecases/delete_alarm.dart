import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/alarm/domain/repositories/alarm_repository.dart';

class DeleteAlarm {
  const DeleteAlarm(this._repository);

  final AlarmRepository _repository;

  Future<Either<Failure, void>> call(String id) =>
      _repository.deleteAlarm(id);
}
