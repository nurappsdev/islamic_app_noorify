import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:islami_app_noorify/features/alarm/data/datasources/alarm_local_data_source.dart';
import 'package:islami_app_noorify/features/alarm/data/datasources/prayer_alarm_local_data_source.dart';
import 'package:islami_app_noorify/features/alarm/data/repositories/alarm_repository_impl.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm_batch.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/prayer_alarm_setting.dart';
import 'package:islami_app_noorify/features/alarm/domain/prayer_alarm_builder.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/add_alarm.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/delete_alarm.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_alarms.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/get_prayer_alarms.dart';
import 'package:islami_app_noorify/features/alarm/domain/usecases/set_alarm_enabled.dart';
import 'package:islami_app_noorify/features/alarm/presentation/bloc/alarm_list/alarm_list_bloc.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

const _times = DailyPrayerTimes(
  dateKey: '2026-09-28',
  readableDate: '28 Sep 2026',
  hijriDate: '',
  fajr: PrayerClockTime(hour: 4, minute: 23),
  sunrise: PrayerClockTime(hour: 5, minute: 40),
  dhuhr: PrayerClockTime(hour: 12, minute: 8),
  asr: PrayerClockTime(hour: 16, minute: 32),
  maghrib: PrayerClockTime(hour: 18, minute: 35),
  sunset: PrayerClockTime(hour: 18, minute: 35),
  isha: PrayerClockTime(hour: 19, minute: 55),
);

class _FakePrayerTimes implements PrayerTimeService {
  const _FakePrayerTimes(this.times);

  final DailyPrayerTimes? times;

  @override
  DailyPrayerTimes? cachedPrayerTimes(DateTime date) => times;

  @override
  Future<DailyPrayerTimes?> loadPrayerTimes(DateTime date) async => times;
}

AlarmEntry _alarm(String id, {int hour = 7, bool enabled = true}) => AlarmEntry(
  id: id,
  hour: hour,
  minute: 0,
  vibrateAndRing: true,
  vibrate: false,
  ring: false,
  enabled: enabled,
);

PrayerAlarm _prayer(List<PrayerAlarm> all, String type) =>
    all.firstWhere((p) => p.prayerType == type);

void main() {
  group('PrayerAlarmBuilder', () {
    test('lists the five prayers then Tahajjud, all off by default', () {
      final alarms = PrayerAlarmBuilder.build(
        settings: const {},
        times: _times,
      );
      expect(alarms.map((a) => a.prayerType), [
        'fajr',
        'dhuhr',
        'asr',
        'maghrib',
        'isha',
        'tahajjud',
      ]);
      expect(alarms.every((a) => !a.isEnabled), isTrue);
    });

    test('rings the chosen number of minutes before the prayer starts', () {
      final alarms = PrayerAlarmBuilder.build(
        settings: const {
          'fajr': PrayerAlarmSetting(
            prayerType: 'fajr',
            enabled: true,
            offsetMinutesBefore: 20,
          ),
        },
        times: _times,
      );
      final fajr = _prayer(alarms, 'fajr');
      expect(fajr.alarmTime, '4:03 AM');
      expect(fajr.timeWindow, '4:23 AM - 5:40 AM');
      expect(fajr.isEnabled, isTrue);
      expect(fajr.offsetMinutesBefore, 20);
    });

    test('wraps around midnight', () {
      final alarms = PrayerAlarmBuilder.build(
        settings: const {
          'fajr': PrayerAlarmSetting(
            prayerType: 'fajr',
            offsetMinutesBefore: 300,
          ),
        },
        times: _times,
      );
      expect(_prayer(alarms, 'fajr').alarmTime, '11:23 PM');
    });

    test('Tahajjud is the last third of the night, ending at Fajr', () {
      final tahajjud = _prayer(
        PrayerAlarmBuilder.build(settings: const {}, times: _times),
        'tahajjud',
      );
      expect(tahajjud.timeWindow, '1:07 AM - 4:23 AM');
    });

    test('without prayer times the times read --:--', () {
      final fajr = _prayer(
        PrayerAlarmBuilder.build(settings: const {}),
        'fajr',
      );
      expect(fajr.alarmTime, '--:--');
      expect(fajr.timeWindow, isEmpty);
    });
  });

  group('on-device alarms', () {
    late Directory tmp;
    late Box<dynamic> alarmsBox;
    late Box<dynamic> prayerBox;
    late AlarmRepositoryImpl repository;

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('alarm_local_test');
      Hive.init(tmp.path);
      final id = DateTime.now().microsecondsSinceEpoch;
      alarmsBox = await Hive.openBox<dynamic>('alarms$id');
      prayerBox = await Hive.openBox<dynamic>('prayers$id');
      repository = AlarmRepositoryImpl(
        alarms: AlarmLocalDataSourceImpl(box: alarmsBox),
        prayerAlarms: PrayerAlarmLocalDataSourceImpl(box: prayerBox),
        prayerTimes: const _FakePrayerTimes(_times),
      );
    });

    tearDown(() async {
      await Hive.close();
      tmp.deleteSync(recursive: true);
    });

    test('creates, updates, disables and deletes a custom alarm', () async {
      await repository.addAlarm(_alarm('a', hour: 9));
      await repository.addAlarm(_alarm('b', hour: 6));

      var alarms = (await repository.getAlarms()).getOrElse(() => const []);
      expect(alarms.map((a) => a.id), ['b', 'a']); // sorted by time of day

      await repository.setAlarmEnabled(id: 'a', enabled: false);
      alarms = (await repository.getAlarms()).getOrElse(() => const []);
      expect(alarms.firstWhere((a) => a.id == 'a').enabled, isFalse);

      await repository.deleteAlarm('a');
      alarms = (await repository.getAlarms()).getOrElse(() => const []);
      expect(alarms.map((a) => a.id), ['b']);
    });

    test('alarms survive reopening the box (they are on the device)', () async {
      await repository.addAlarm(_alarm('a'));
      final name = alarmsBox.name;
      await alarmsBox.close();
      final reopened = await Hive.openBox<dynamic>(name);

      final alarms = await AlarmLocalDataSourceImpl(box: reopened).getAlarms();
      expect(alarms.map((a) => a.id), ['a']);
    });

    test('Set All turns the picked prayers on and the rest off, saved '
        'locally', () async {
      final result = await repository.setAllPrayerAlarms(
        const PrayerAlarmBatch(
          offsetMinutesBefore: 30,
          soundMode: 'vibrate',
          ringtoneId: 'adhan_2',
          ringtoneName: 'Adhan 2',
          ringtoneUrl: 'https://x/2.mp3',
          selectedPrayers: ['fajr', 'dhuhr', 'maghrib', 'isha'],
        ),
      );
      expect(result.isRight(), isTrue);

      final saved = await PrayerAlarmLocalDataSourceImpl(
        box: prayerBox,
      ).getSettings();
      expect(saved['fajr']!.enabled, isTrue);
      expect(saved['asr']!.enabled, isFalse);
      expect(saved['tahajjud']!.enabled, isFalse);
      expect(saved['fajr']!.offsetMinutesBefore, 30);
      expect(saved['fajr']!.soundMode, 'vibrate');
      expect(saved['fajr']!.ringtoneName, 'Adhan 2');
      expect(saved['fajr']!.ringtoneUrl, 'https://x/2.mp3');

      final alarms = (await repository.getPrayerAlarms()).getOrElse(
        () => const [],
      );
      expect(_prayer(alarms, 'fajr').alarmTime, '3:53 AM'); // 4:23 - 30
      expect(_prayer(alarms, 'asr').isEnabled, isFalse);
    });

    test(
      'a second Set All turns a prayer off but keeps its settings',
      () async {
        await repository.setAllPrayerAlarms(
          const PrayerAlarmBatch(
            offsetMinutesBefore: 40,
            soundMode: 'ring',
            ringtoneId: 'r',
            selectedPrayers: ['fajr', 'asr'],
          ),
        );
        await repository.setAllPrayerAlarms(
          const PrayerAlarmBatch(
            offsetMinutesBefore: 20,
            soundMode: 'vibrate',
            ringtoneId: 'r2',
            selectedPrayers: ['fajr'],
          ),
        );

        final saved = await PrayerAlarmLocalDataSourceImpl(
          box: prayerBox,
        ).getSettings();
        expect(saved['fajr']!.offsetMinutesBefore, 20);
        expect(saved['asr']!.enabled, isFalse);
        expect(saved['asr']!.offsetMinutesBefore, 40); // what it had
        expect(saved['asr']!.soundMode, 'ring');
      },
    );

    test('prayer alarms still load, with no time, when prayer times are '
        'unavailable', () async {
      final offline = AlarmRepositoryImpl(
        alarms: AlarmLocalDataSourceImpl(box: alarmsBox),
        prayerAlarms: PrayerAlarmLocalDataSourceImpl(box: prayerBox),
        prayerTimes: const _FakePrayerTimes(null),
      );
      final alarms = (await offline.getPrayerAlarms()).getOrElse(
        () => const [],
      );
      expect(alarms, hasLength(6));
      expect(_prayer(alarms, 'fajr').alarmTime, '--:--');
    });

    group('AlarmListBloc', () {
      late List<String> events;
      late AlarmListBloc bloc;

      setUp(() {
        events = [];
        bloc = AlarmListBloc(
          getAlarms: GetAlarms(repository),
          getPrayerAlarms: GetPrayerAlarms(repository),
          addAlarm: AddAlarm(repository),
          setAlarmEnabled: SetAlarmEnabled(repository),
          deleteAlarm: DeleteAlarm(repository),
          syncAlarms: () async => events.add('sync'),
          cancelAlarm: (id, reason) async => events.add('cancel $id'),
        );
      });

      tearDown(() => bloc.close());

      // Long enough for the bloc's Hive writes to finish, even on a busy
      // machine.
      Future<void> settle() =>
          Future<void>.delayed(const Duration(milliseconds: 30));

      test('loads the saved alarms and the prayer alarms', () async {
        await repository.addAlarm(_alarm('a'));
        bloc.add(const LoadAlarms());
        await settle();
        await settle();

        expect(bloc.state.status, AlarmListStatus.success);
        expect(bloc.state.alarms.map((a) => a.id), ['a']);
        expect(bloc.state.prayerAlarms, hasLength(6));
      });

      test('saving an alarm stores it and re-arms the schedule', () async {
        bloc.add(SaveAlarm(_alarm('new')));
        await settle();
        await settle();

        expect(bloc.state.alarms.map((a) => a.id), ['new']);
        expect(alarmsBox.containsKey('new'), isTrue);
        expect(events, ['sync']);
      });

      test('switching an alarm off cancels it and re-syncs', () async {
        await repository.addAlarm(_alarm('a'));
        bloc.add(const LoadAlarms());
        await settle();
        await settle();
        events.clear();

        bloc.add(const ToggleAlarmEnabled('a', false));
        await settle();
        await settle();

        expect(bloc.state.alarms.single.enabled, isFalse);
        expect(events, ['cancel a', 'sync']);
      });

      test(
        'deleting an alarm removes it and cancels its OS alarm at once',
        () async {
          await repository.addAlarm(_alarm('a'));
          bloc.add(const LoadAlarms());
          await settle();
          await settle();
          events.clear();

          bloc.add(const RemoveAlarm('a'));
          await settle();
          await settle();

          expect(bloc.state.alarms, isEmpty);
          expect(alarmsBox.containsKey('a'), isFalse);
          expect(events, ['cancel a', 'sync']);
        },
      );
    });
  });

  test('outside the ringtone data source, the alarm feature makes no network '
      'call', () {
    final offenders = <String>[];
    final files = Directory('lib/features/alarm')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      if (file.path.endsWith('ringtone_remote_data_source.dart')) continue;
      final source = file.readAsStringSync();
      if (RegExp(
        r"package:dio/|dio_client|api_constants|package:http/",
      ).hasMatch(source)) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty, reason: 'network code found in $offenders');
  });

  test('the ringtone list is the only alarm endpoint left', () {
    final constants = File(
      'lib/core/services/api_constants.dart',
    ).readAsStringSync();
    final alarmEndpoints = RegExp(
      r'''["']/alarms[^"']*["']''',
    ).allMatches(constants).map((m) => m.group(0)).toList();
    expect(alarmEndpoints, ['"/alarms/ringtones"']);
  });
}
