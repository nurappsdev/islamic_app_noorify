import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/alarm_entry.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/prayer_alarm_batch.dart';

/// The user's alarms. Everything here lives on the device: nothing is sent to
/// or read from the server.
abstract interface class AlarmRepository {
  /// All custom alarms, sorted by time of day.
  Future<Either<Failure, List<AlarmEntry>>> getAlarms();

  /// The six prayer alarms - their saved settings worked out against today's
  /// prayer times - whether or not they are turned on.
  Future<Either<Failure, List<PrayerAlarm>>> getPrayerAlarms();

  /// Saves [alarm] and returns it back.
  Future<Either<Failure, AlarmEntry>> addAlarm(AlarmEntry alarm);

  /// Turns the alarm identified by [id] on or off.
  Future<Either<Failure, void>> setAlarmEnabled({
    required String id,
    required bool enabled,
  });

  /// Deletes the alarm identified by [id].
  Future<Either<Failure, void>> deleteAlarm(String id);

  /// Applies [batch] to the prayer alarms: selected prayers are turned on
  /// with its settings, the rest are turned off.
  Future<Either<Failure, void>> setAllPrayerAlarms(PrayerAlarmBatch batch);

  /// Turns the single prayer alarm [prayerType] on or off, leaving every
  /// other prayer — and this one's own saved offset, sound mode and ringtone —
  /// untouched, so turning it back on reactivates exactly what it had.
  Future<Either<Failure, void>> setPrayerAlarmEnabled({
    required String prayerType,
    required bool enabled,
  });
}
