import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/alarm/data/datasources/alarm_local_data_source.dart';
import 'package:tuhfatul_muslim/features/alarm/data/datasources/prayer_alarm_local_data_source.dart';
import 'package:tuhfatul_muslim/features/alarm/data/models/alarm_model.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/alarm_entry.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/prayer_alarm_batch.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/prayer_alarm_setting.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/prayer_alarm_builder.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/repositories/alarm_repository.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_time_service.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';

/// The alarms, kept entirely on the device (Hive). No server call is made.
///
/// Prayer alarms need the day's prayer times to work out when they ring; those
/// come from the same prayer-times service (and on-device cache) the home
/// screen uses.
class AlarmRepositoryImpl implements AlarmRepository {
  AlarmRepositoryImpl({
    AlarmLocalDataSource? alarms,
    PrayerAlarmLocalDataSource? prayerAlarms,
    PrayerTimeService? prayerTimes,
    DateTime Function()? now,
  }) : _alarms = alarms ?? AlarmLocalDataSourceImpl(),
       _prayerAlarms = prayerAlarms ?? PrayerAlarmLocalDataSourceImpl(),
       _prayerTimes = prayerTimes,
       _now = now ?? bangladeshNow;

  final AlarmLocalDataSource _alarms;
  final PrayerAlarmLocalDataSource _prayerAlarms;
  PrayerTimeService? _prayerTimes;
  final DateTime Function() _now;

  @override
  Future<Either<Failure, List<AlarmEntry>>> getAlarms() =>
      _guard(() => _alarms.getAlarms());

  @override
  Future<Either<Failure, List<PrayerAlarm>>> getPrayerAlarms() {
    return _guard(() async {
      final settings = await _prayerAlarms.getSettings();
      return PrayerAlarmBuilder.build(
        settings: settings,
        times: await _todaysPrayerTimes(),
      );
    });
  }

  @override
  Future<Either<Failure, AlarmEntry>> addAlarm(AlarmEntry alarm) =>
      _guard(() => _alarms.addAlarm(AlarmModel.fromEntity(alarm)));

  @override
  Future<Either<Failure, void>> setAlarmEnabled({
    required String id,
    required bool enabled,
  }) => _guard(() => _alarms.setAlarmEnabled(id: id, enabled: enabled));

  @override
  Future<Either<Failure, void>> deleteAlarm(String id) =>
      _guard(() => _alarms.deleteAlarm(id));

  @override
  Future<Either<Failure, void>> setAllPrayerAlarms(PrayerAlarmBatch batch) {
    return _guard(() async {
      final saved = await _prayerAlarms.getSettings();
      await _prayerAlarms.saveSettings([
        for (final type in PrayerAlarmBuilder.prayerTypes)
          _apply(saved[type] ?? PrayerAlarmSetting(prayerType: type), batch),
      ]);
    });
  }

  /// A selected prayer takes the batch's settings and is turned on; any other
  /// is only turned off, keeping what it had.
  PrayerAlarmSetting _apply(
    PrayerAlarmSetting setting,
    PrayerAlarmBatch batch,
  ) {
    if (!batch.selectedPrayers.contains(setting.prayerType)) {
      return setting.copyWith(enabled: false);
    }
    return setting.copyWith(
      enabled: true,
      offsetMinutesBefore: batch.offsetMinutesBefore,
      soundMode: batch.soundMode,
      ringtoneId: batch.ringtoneId,
      ringtoneName: batch.ringtoneName,
      ringtoneUrl: batch.ringtoneUrl,
    );
  }

  /// Today's prayer times: the on-device cache first, then the prayer-times
  /// service; `null` when neither has them (offline, nothing cached).
  Future<DailyPrayerTimes?> _todaysPrayerTimes() async {
    try {
      final service = _prayerTimes ??= await AladhanPrayerTimeService.create();
      final now = _now();
      return service.cachedPrayerTimes(now) ??
          await service.loadPrayerTimes(now);
    } catch (_) {
      return null;
    }
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
