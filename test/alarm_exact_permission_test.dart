import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/alarm/presentation/widgets/exact_alarm_permission_gate.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Pumps a screen with a single button that runs the gate and records what it
/// answered, so each test can drive the dialog the way a user would.
Future<List<bool>> _pumpGate(
  WidgetTester tester, {
  required bool granted,
  Future<bool> Function()? openSettings,
}) async {
  final answers = <bool>[];
  final bloc = LanguageBloc(
    initialLanguage: AppLanguage.english,
    persist: (_) async {},
  );
  addTearDown(bloc.close);
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async => answers.add(
                  await ensureExactAlarmAccess(
                    context,
                    hasPermission: () async => granted,
                    openSettings: openSettings ?? () async => false,
                  ),
                ),
                child: const Text('enable'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('enable'));
  await tester.pumpAndSettle();
  return answers;
}

void main() {
  setUpAll(AppText.load);

  AppText appText() => AppText.forLanguage(AppLanguage.english);

  testWidgets('already granted: no dialog, the alarm is just enabled', (
    tester,
  ) async {
    final answers = await _pumpGate(tester, granted: true);
    expect(find.byType(AlertDialog), findsNothing);
    expect(answers, [true]);
  });

  testWidgets('not granted: explains first, with Cancel and Allow', (
    tester,
  ) async {
    await _pumpGate(tester, granted: false);
    expect(find.text(appText().exactAlarmPermissionTitle), findsOne);
    expect(find.text(appText().exactAlarmPermissionExplanation), findsOne);
    expect(find.text(appText().alarmCancel), findsOne);
    expect(find.text(appText().exactAlarmPermissionAllow), findsOne);
  });

  testWidgets('Cancel never opens settings and leaves the alarm off', (
    tester,
  ) async {
    var opened = false;
    final answers = await _pumpGate(
      tester,
      granted: false,
      openSettings: () async {
        opened = true;
        return true;
      },
    );
    await tester.tap(find.text(appText().alarmCancel));
    await tester.pumpAndSettle();
    expect(opened, isFalse);
    expect(answers, [false]);
  });

  testWidgets('Allow opens settings; granted on return enables the alarm', (
    tester,
  ) async {
    var opened = 0;
    final answers = await _pumpGate(
      tester,
      granted: false,
      openSettings: () async {
        opened++;
        return true;
      },
    );
    await tester.tap(find.text(appText().exactAlarmPermissionAllow));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(answers, [true]);
  });

  testWidgets('Allow but still denied on return leaves the alarm off', (
    tester,
  ) async {
    final answers = await _pumpGate(
      tester,
      granted: false,
      openSettings: () async => false,
    );
    await tester.tap(find.text(appText().exactAlarmPermissionAllow));
    await tester.pumpAndSettle();
    expect(answers, [false]);
  });

  test('the app never asks for exact-alarm access at startup', () {
    // Removing this request is the whole point: it is asked for only when an
    // alarm is turned on (see `ensureExactAlarmAccess`).
    final source = File(
      'lib/features/alarm/data/services/alarm_scheduler.dart',
    ).readAsStringSync();
    expect(source.contains('requestExactAlarmsPermission'), isTrue);
    final init = source.substring(
      source.indexOf('static Future<void> init()'),
      source.indexOf('static AndroidFlutterLocalNotificationsPlugin? get'),
    );
    expect(init.contains('requestExactAlarmsPermission'), isFalse);
  });
}
