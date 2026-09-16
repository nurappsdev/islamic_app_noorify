import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_dashboard.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/ringtone.dart';

abstract interface class AlarmRepository {
  /// All saved alarms, sorted by time of day.
  Future<Either<Failure, List<AlarmEntry>>> getAlarms();

  /// The alarm dashboard (`GET /alarms`) — the countdown text and the
  /// prayer-alarms list shown on the "Prayers Alarm" tab.
  Future<Either<Failure, AlarmDashboard>> getAlarmDashboard();

  /// The alarm ringtone catalog (`GET /alarms/ringtones`).
  Future<Either<Failure, List<Ringtone>>> getRingtones();

  /// Persists [alarm] and returns it back once saved.
  Future<Either<Failure, AlarmEntry>> addAlarm(AlarmEntry alarm);

  /// Flips the enabled state of the alarm identified by [id] via
  /// `PATCH /alarms/custom/{id}`, then mirrors it in the local cache.
  Future<Either<Failure, void>> setAlarmEnabled({
    required String id,
    required bool enabled,
  });

  /// Deletes the alarm identified by [id] via `DELETE /alarms/custom/{id}`,
  /// then removes it from the local cache.
  Future<Either<Failure, void>> deleteAlarm(String id);
}
