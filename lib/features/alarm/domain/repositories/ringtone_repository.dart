import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/ringtone.dart';

/// The ringtones an admin makes available for alarms. This is the only alarm
/// data that comes from the server.
abstract interface class RingtoneRepository {
  /// The ringtone catalog (`GET /alarms/ringtones`).
  Future<Either<Failure, List<Ringtone>>> getRingtones();
}
