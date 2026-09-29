import 'package:hive/hive.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/features/alarm/data/models/prayer_alarm_setting_model.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/prayer_alarm_setting.dart';

/// Hive-backed storage for the prayer alarm settings - one entry per prayer,
/// keyed by its type. Throws [CacheException]; never returns error states.
abstract interface class PrayerAlarmLocalDataSource {
  /// The saved settings by prayer type; a prayer never saved is absent.
  Future<Map<String, PrayerAlarmSetting>> getSettings();

  Future<void> saveSettings(Iterable<PrayerAlarmSetting> settings);
}

class PrayerAlarmLocalDataSourceImpl implements PrayerAlarmLocalDataSource {
  PrayerAlarmLocalDataSourceImpl({Box<dynamic>? box})
    : _box = box ?? HiveService.prayerAlarms;

  final Box<dynamic> _box;

  @override
  Future<Map<String, PrayerAlarmSetting>> getSettings() async {
    try {
      final settings = <String, PrayerAlarmSetting>{};
      for (final raw in _box.values.whereType<Map>()) {
        try {
          final setting = PrayerAlarmSettingModel.fromJson(
            Map<String, dynamic>.from(raw),
          );
          settings[setting.prayerType] = setting;
        } catch (_) {
          // One unreadable entry is treated as never saved; the rest load.
        }
      }
      return settings;
    } catch (_) {
      throw CacheException();
    }
  }

  @override
  Future<void> saveSettings(Iterable<PrayerAlarmSetting> settings) async {
    try {
      await _box.putAll({
        for (final setting in settings)
          setting.prayerType: PrayerAlarmSettingModel.fromEntity(
            setting,
          ).toJson(),
      });
    } catch (_) {
      throw CacheException();
    }
  }
}
