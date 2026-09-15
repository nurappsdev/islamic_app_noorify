import 'package:hive/hive.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/storage/hive_service.dart';
import 'package:islami_app_noorify/features/alarm/data/models/alarm_model.dart';

/// Hive-backed local persistence for saved alarms — one box entry per alarm,
/// keyed by its id. Throws [CacheException]; never returns error states.
abstract interface class AlarmLocalDataSource {
  Future<List<AlarmModel>> getAlarms();

  Future<AlarmModel> addAlarm(AlarmModel alarm);

  Future<void> setAlarmEnabled({required String id, required bool enabled});
}

class AlarmLocalDataSourceImpl implements AlarmLocalDataSource {
  AlarmLocalDataSourceImpl({Box<dynamic>? box})
    : _box = box ?? HiveService.alarms;

  final Box<dynamic> _box;

  @override
  Future<List<AlarmModel>> getAlarms() async {
    try {
      final alarms = _box.values
          .whereType<Map>()
          .map((raw) => AlarmModel.fromJson(Map<String, dynamic>.from(raw)))
          .toList();
      alarms.sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );
      return alarms;
    } catch (_) {
      throw CacheException();
    }
  }

  @override
  Future<AlarmModel> addAlarm(AlarmModel alarm) async {
    try {
      await _box.put(alarm.id, alarm.toJson());
      return alarm;
    } catch (_) {
      throw CacheException();
    }
  }

  @override
  Future<void> setAlarmEnabled({
    required String id,
    required bool enabled,
  }) async {
    try {
      final raw = _box.get(id);
      if (raw is! Map) return;
      final updated = AlarmModel.fromJson(
        Map<String, dynamic>.from(raw),
      ).copyWith(enabled: enabled);
      await _box.put(id, AlarmModel.fromEntity(updated).toJson());
    } catch (_) {
      throw CacheException();
    }
  }
}
