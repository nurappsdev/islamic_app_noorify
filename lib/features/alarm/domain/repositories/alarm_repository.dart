import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/ringtone.dart';

abstract interface class AlarmRepository {
  /// All saved alarms, sorted by time of day.
  Future<Either<Failure, List<AlarmEntry>>> getAlarms();

  /// The alarm ringtone catalog (`GET /alarms/ringtones`).
  Future<Either<Failure, List<Ringtone>>> getRingtones();

  /// Persists [alarm] and returns it back once saved.
  Future<Either<Failure, AlarmEntry>> addAlarm(AlarmEntry alarm);

  /// Flips the enabled state of the alarm identified by [id].
  Future<Either<Failure, void>> setAlarmEnabled({
    required String id,
    required bool enabled,
  });
}
