import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/repositories/alarm_repository.dart';

class DeleteAlarm {
  const DeleteAlarm(this._repository);

  final AlarmRepository _repository;

  Future<Either<Failure, void>> call(String id) => _repository.deleteAlarm(id);
}
