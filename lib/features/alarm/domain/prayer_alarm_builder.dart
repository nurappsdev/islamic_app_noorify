import 'package:tuhfatul_muslim/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/prayer_alarm_setting.dart';
import 'package:tuhfatul_muslim/features/home/domain/current_prayer.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';

/// Works out the prayer alarms from the saved settings and a day's prayer
/// times. Pure: nothing is read or written here.
class PrayerAlarmBuilder {
  const PrayerAlarmBuilder._();

  static const tahajjud = 'tahajjud';

  /// The alarm types, in the order the screens list them.
  static final prayerTypes = [
    ...PrayerPeriod.values.map((period) => period.name),
    tahajjud,
  ];

  static const _minutesPerDay = 24 * 60;

  /// One [PrayerAlarm] per prayer type. A prayer with no saved setting is
  /// turned off. Without [times] the times read `--:--`.
  static List<PrayerAlarm> build({
    required Map<String, PrayerAlarmSetting> settings,
    DailyPrayerTimes? times,
  }) {
    return [
      for (final type in prayerTypes)
        _build(settings[type] ?? PrayerAlarmSetting(prayerType: type), times),
    ];
  }

  static PrayerAlarm _build(
    PrayerAlarmSetting setting,
    DailyPrayerTimes? times,
  ) {
    final window = times == null ? null : _window(setting.prayerType, times);
    final alarm = window == null
        ? null
        : _shift(window.start, -setting.offsetMinutesBefore);
    return PrayerAlarm(
      prayerType: setting.prayerType,
      timeWindow: window == null
          ? ''
          : '${formatPrayerTime(window.start)} - ${formatPrayerTime(window.end)}',
      alarmTime: alarm == null ? '--:--' : formatPrayerTime(alarm),
      offsetMinutesBefore: setting.offsetMinutesBefore,
      soundMode: setting.soundMode,
      ringtoneId: setting.ringtoneId,
      ringtoneName: setting.ringtoneName,
      ringtoneUrl: setting.ringtoneUrl,
      isEnabled: setting.enabled,
    );
  }

  static ({PrayerClockTime start, PrayerClockTime end})? _window(
    String type,
    DailyPrayerTimes times,
  ) {
    if (type == tahajjud) {
      // The last third of the night, from Maghrib to the next Fajr.
      final nightStart = times.maghrib.totalMinutes;
      final night = times.fajr.totalMinutes + _minutesPerDay - nightStart;
      return (
        start: _shift(times.maghrib, (night * 2 / 3).round()),
        end: times.fajr,
      );
    }
    final period = PrayerPeriod.values.where((p) => p.name == type).firstOrNull;
    if (period == null) return null;
    return (start: prayerStart(period, times), end: prayerEnd(period, times));
  }

  /// [time] moved by [minutes], wrapping around midnight.
  static PrayerClockTime _shift(PrayerClockTime time, int minutes) {
    final total =
        ((time.totalMinutes + minutes) % _minutesPerDay + _minutesPerDay) %
        _minutesPerDay;
    return PrayerClockTime(hour: total ~/ 60, minute: total % 60);
  }
}
