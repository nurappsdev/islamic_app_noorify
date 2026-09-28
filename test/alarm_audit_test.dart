import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/alarm/data/models/custom_alarm_model.dart';
import 'package:islami_app_noorify/features/alarm/data/services/alarm_log.dart';
import 'package:islami_app_noorify/features/alarm/data/services/alarm_scheduler.dart';
import 'package:islami_app_noorify/features/alarm/data/services/alarm_sync_plan.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

AlarmEntry _alarm(
  String id, {
  int hour = 7,
  int minute = 0,
  bool enabled = true,
}) => AlarmEntry(
  id: id,
  hour: hour,
  minute: minute,
  vibrateAndRing: true,
  vibrate: false,
  ring: false,
  enabled: enabled,
);

PrayerAlarm _prayer(
  String type, {
  String time = '04:10 AM',
  bool enabled = true,
}) => PrayerAlarm(
  prayerType: type,
  title: type,
  timeWindow: '',
  alarmTime: time,
  offsetMinutesBefore: 10,
  soundMode: 'vibrate_and_ring',
  ringtoneId: 'makkah_adhan',
  ringtoneName: 'Makkah',
  isEnabled: enabled,
);

void main() {
  group('OS alarm ids', () {
    test('do not change between runs or app updates', () {
      // Pinned values: if these move, alarms armed by the previous version
      // could no longer be found and cancelled.
      expect(alarmManagerIdFor('prayer_fajr'), 1500102292);
      expect(alarmManagerIdFor('prayer_dhuhr'), 449733816);
      expect(alarmManagerIdFor('abc123'), 1902457866);
    });

    test('are positive 32-bit ints, even, with the odd id kept for snooze', () {
      for (final id in ['prayer_fajr', '665f1c2e9b1d', '', 'x' * 200]) {
        final osId = alarmManagerIdFor(id);
        expect(osId, inInclusiveRange(0, 0x7fffffff));
        expect(osId.isEven, isTrue);
      }
    });

    test('are unique across a realistic set of alarm ids', () {
      final ids = [
        for (final type in [
          'fajr',
          'sunrise',
          'dhuhr',
          'asr',
          'maghrib',
          'isha',
          'tahajjud',
        ])
          'prayer_$type',
        for (var i = 0; i < 2000; i++) 'a${i.toRadixString(16)}b9c04e77d1',
      ];
      expect({for (final id in ids) alarmManagerIdFor(id)}.length, ids.length);
    });
  });

  group('AlarmSyncPlan', () {
    AlarmSyncPlan plan({
      List<AlarmEntry> custom = const [],
      List<PrayerAlarm> prayers = const [],
      Set<String> picked = const {},
    }) => AlarmSyncPlan.build(
      customAlarms: custom,
      prayers: prayers,
      userPrayerTypes: picked,
      ringtoneUrls: const {'makkah_adhan': 'https://x/adhan.mp3'},
    );

    test('arms enabled server alarms and disarms disabled ones', () {
      final p = plan(custom: [_alarm('a'), _alarm('b', enabled: false)]);
      expect(p.armed.map((a) => a.id), ['a']);
      expect(p.skipped, {'b': 'disabled'});
    });

    test('never arms an alarm that has no id', () {
      final p = plan(custom: [_alarm('')]);
      expect(p.armed, isEmpty);
      expect(p.skipped, isEmpty);
    });

    test('only prayers picked on this device ring, even if the server '
        'pre-enables them', () {
      final p = plan(
        prayers: [_prayer('fajr'), _prayer('isha')],
        picked: {'fajr'},
      );
      expect(p.armed.map((a) => a.id), ['prayer_fajr']);
      expect(p.skipped['prayer_isha'], 'not selected on this device');
      expect(p.armed.single.ringtoneUrl, 'https://x/adhan.mp3');
      expect(p.armed.single.hour, 4);
      expect(p.armed.single.minute, 10);
    });

    test('a prayer alarm with an unreadable time is disarmed', () {
      final p = plan(
        prayers: [_prayer('fajr', time: 'garbage')],
        picked: {'fajr'},
      );
      expect(p.armed, isEmpty);
      expect(p.skipped['prayer_fajr'], contains('unreadable time'));
    });

    test('reports alarms that share a time', () {
      final p = plan(
        custom: [
          _alarm('a', hour: 5, minute: 30),
          _alarm('b', hour: 5, minute: 30),
        ],
      );
      expect(p.duplicateTimes, ['05:30']);
    });
  });

  group('CustomAlarmModel', () {
    test('an unreadable time is left off instead of ringing at 12:00 AM', () {
      final alarm = CustomAlarmModel.fromJson({
        'id': 'x',
        'time': '',
        'isEnabled': true,
      });
      expect(alarm.enabled, isFalse);
    });

    test('a readable time keeps the server\'s enabled flag', () {
      final on = CustomAlarmModel.fromJson({
        'id': 'x',
        'time': '07:30 AM',
        'isEnabled': true,
      });
      final off = CustomAlarmModel.fromJson({
        'id': 'y',
        'time': '07:30 AM',
        'isEnabled': false,
      });
      expect(on.enabled, isTrue);
      expect((on.hour, on.minute), (7, 30));
      expect(off.enabled, isFalse);
    });
  });

  group('AlarmLog', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('records id, name, trigger time, source and status', () async {
      await AlarmLog.record(
        'arm',
        id: 'prayer_fajr',
        name: 'Fajr',
        at: DateTime(2026, 9, 29, 4, 10),
        source: AlarmSource.backend,
        status: 'ok',
      );

      final line = (await AlarmLog.history()).single;
      expect(line, contains('| arm |'));
      expect(line, contains('id=prayer_fajr'));
      expect(line, contains('name="Fajr"'));
      expect(line, contains('at=2026-09-29T04:10:00.000'));
      expect(line, contains('source=backend'));
      expect(line, contains('status=ok'));
    });

    test('keeps only the most recent events', () async {
      for (var i = 0; i < 200; i++) {
        await AlarmLog.record('arm', id: 'a$i');
      }
      final lines = await AlarmLog.history();
      expect(lines, hasLength(150));
      expect(lines.last, contains('id=a199'));
    });
  });
}
