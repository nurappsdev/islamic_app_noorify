import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/ringtone.dart';
import 'package:islami_app_noorify/features/alarm/domain/repositories/ringtone_repository.dart';

class GetRingtones {
  const GetRingtones(this._repository);

  final RingtoneRepository _repository;

  Future<Either<Failure, List<Ringtone>>> call() => _repository.getRingtones();
}
