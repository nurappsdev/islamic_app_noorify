import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/alarm/data/datasources/prayer_alarm_local_data_source.dart';
import 'package:tuhfatul_muslim/features/alarm/domain/entities/prayer_alarm_setting.dart';
import 'package:tuhfatul_muslim/features/alarm/presentation/screens/all_alarm_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Opens the Alarm screen on its "Prayers Alarm" tab, the way a user gets
/// there: the screen reads the prayer alarms saved on the device itself.
Future<void> _openPrayerTab(WidgetTester tester) async {
  final bloc = LanguageBloc(
    initialLanguage: AppLanguage.english,
    persist: (_) async {},
  );
  addTearDown(bloc.close);
  tester.view.physicalSize = const Size(375 * 2, 812 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const MaterialApp(home: AllAlarmScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(
    find.text(AppText.forLanguage(AppLanguage.english).prayersAlarm),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppText.load();
    final dir = Directory.systemTemp.createTempSync('prayer_toggle_hive');
    Hive.init(dir.path);
    for (final name in [HiveService.alarmsBox, HiveService.prayerAlarmsBox]) {
      await Hive.openBox<dynamic>(name);
    }
  });

  setUp(() async {
    await HiveService.prayerAlarms.clear();
    // Fajr on, the rest off — enough to tell the toggles apart.
    await PrayerAlarmLocalDataSourceImpl().saveSettings([
      const PrayerAlarmSetting(
        prayerType: 'fajr',
        enabled: true,
        offsetMinutesBefore: 20,
        soundMode: 'ring',
        ringtoneId: 'r1',
        ringtoneName: 'R1',
      ),
    ]);
  });

  testWidgets('every prayer row has its own toggle, and no alarm icon', (
    tester,
  ) async {
    await _openPrayerTab(tester);

    // Fajr, Dhuhr, Asr, Maghrib, Isha and Tahajjud.
    expect(find.byType(Switch), findsNWidgets(6));
    expect(find.byIcon(Icons.access_alarm), findsNothing);
  });

  testWidgets('each toggle shows that prayer\'s own saved state', (
    tester,
  ) async {
    await _openPrayerTab(tester);

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches.first.value, isTrue); // fajr
    expect(switches.skip(1).map((s) => s.value), everyElement(isFalse));
  });

  testWidgets('switching one prayer off saves only that prayer', (
    tester,
  ) async {
    await _openPrayerTab(tester);
    // Turn a second prayer on first, so there is one to leave untouched.
    await tester.tap(find.byType(Switch).at(1));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byType(Switch).first);
    await tester.pump(const Duration(milliseconds: 200));

    final saved = await PrayerAlarmLocalDataSourceImpl().getSettings();
    expect(saved['fajr']!.enabled, isFalse);
    expect(saved['dhuhr']!.enabled, isTrue);
    // Switched off, Fajr still remembers what it was set up with.
    expect(saved['fajr']!.offsetMinutesBefore, 20);
    expect(saved['fajr']!.soundMode, 'ring');
    expect(saved['fajr']!.ringtoneId, 'r1');
  });
}
