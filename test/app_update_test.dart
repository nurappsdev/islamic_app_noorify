import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuhfatul_muslim/core/update/app_update_reminder.dart';
import 'package:tuhfatul_muslim/core/update/app_update_texts.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/core/widgets/app_update_dialog.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// The keys [AppUpdateReminder] writes, so a "Later" from days ago can be
/// staged without waiting for the clock.
const _snoozedAtKey = 'app_update_snoozed_at';
const _snoozedVersionKey = 'app_update_snoozed_version_code';

void _stageSnooze({required Duration ago, int? versionCode}) {
  SharedPreferences.setMockInitialValues({
    _snoozedAtKey: DateTime.now().subtract(ago).millisecondsSinceEpoch,
    if (versionCode != null) _snoozedVersionKey: versionCode,
  });
}

/// Opens the update dialog over a bare screen in [language].
Future<void> _showDialog(
  WidgetTester tester, {
  AppLanguage language = AppLanguage.bangla,
  bool readyToInstall = false,
}) async {
  tester.view.physicalSize = const Size(375 * 2, 812 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final bloc = LanguageBloc(initialLanguage: language, persist: (_) async {});
  addTearDown(bloc.close);

  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showAppUpdateDialog(
                  context,
                  readyToInstall: readyToInstall,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

List<String> _visible(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    if (text.data != null) text.data!,
];

void main() {
  group('AppUpdateReminder', () {
    test('nothing is held back before the user ever chooses Later', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await AppUpdateReminder.isSnoozed(8), isFalse);
    });

    test('Later holds the same build back', () async {
      SharedPreferences.setMockInitialValues({});
      await AppUpdateReminder.snooze(8);
      expect(await AppUpdateReminder.isSnoozed(8), isTrue);
    });

    test('the reminder comes back after three days', () async {
      _stageSnooze(ago: const Duration(days: 2, hours: 23), versionCode: 8);
      expect(await AppUpdateReminder.isSnoozed(8), isTrue);

      _stageSnooze(
        ago: AppUpdateReminder.reminderInterval + const Duration(minutes: 1),
        versionCode: 8,
      );
      expect(await AppUpdateReminder.isSnoozed(8), isFalse);
    });

    test('a newer release is offered without waiting', () async {
      _stageSnooze(ago: const Duration(hours: 1), versionCode: 8);
      expect(await AppUpdateReminder.isSnoozed(9), isFalse);
      expect(await AppUpdateReminder.isSnoozed(8), isTrue);
      // An older build on offer is the one that was put off, or older still.
      expect(await AppUpdateReminder.isSnoozed(7), isTrue);
    });

    test('a clock set backwards does not hide the prompt', () async {
      _stageSnooze(ago: const Duration(days: -2), versionCode: 8);
      expect(await AppUpdateReminder.isSnoozed(8), isFalse);
    });

    test('clear forgets the postponement', () async {
      _stageSnooze(ago: const Duration(hours: 1), versionCode: 8);
      await AppUpdateReminder.clear();
      expect(await AppUpdateReminder.isSnoozed(8), isFalse);
    });
  });

  group('AppUpdateTexts', () {
    const texts = <String, LocalizedText>{
      'title': AppUpdateTexts.title,
      'message': AppUpdateTexts.message,
      'later': AppUpdateTexts.later,
      'updateNow': AppUpdateTexts.updateNow,
      'downloadingTitle': AppUpdateTexts.downloadingTitle,
      'downloadingMessage': AppUpdateTexts.downloadingMessage,
      'keepBrowsing': AppUpdateTexts.keepBrowsing,
      'readyTitle': AppUpdateTexts.readyTitle,
      'readyMessage': AppUpdateTexts.readyMessage,
      'restartAndInstall': AppUpdateTexts.restartAndInstall,
      'downloadFailed': AppUpdateTexts.downloadFailed,
    };

    for (final language in AppLanguage.values) {
      test('every prompt is written in ${language.name}', () {
        texts.forEach((name, text) {
          final resolved = language == AppLanguage.bangla
              ? text.bn
              : text.en;
          expect(resolved, isNotNull, reason: name);
          expect(resolved, isNotEmpty, reason: name);
        });
      });
    }
  });

  group('the update dialog', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('offers Update Now and Later', (tester) async {
      await _showDialog(tester);
      final visible = _visible(tester);
      expect(visible, contains(AppUpdateTexts.title.bn));
      expect(visible, contains(AppUpdateTexts.message.bn));
      expect(visible, contains(AppUpdateTexts.updateNow.bn));
      expect(visible, contains(AppUpdateTexts.later.bn));
    });

    testWidgets('is written in English when that is the app language', (
      tester,
    ) async {
      await _showDialog(tester, language: AppLanguage.english);
      final visible = _visible(tester);
      expect(visible, contains(AppUpdateTexts.title.en));
      expect(visible, contains(AppUpdateTexts.updateNow.en));
      expect(visible, contains(AppUpdateTexts.later.en));
    });

    testWidgets('Later closes it and holds the prompt back', (tester) async {
      await _showDialog(tester);
      await tester.tap(find.text(AppUpdateTexts.later.bn!));
      await tester.pumpAndSettle();

      expect(find.text(AppUpdateTexts.title.bn!), findsNothing);
      expect(isAppUpdateDialogVisible, isFalse);
      // No check ran in the test, so the build put off has no version code.
      expect(await AppUpdateReminder.isSnoozed(null), isTrue);
    });

    testWidgets('a downloaded update opens on the restart step', (
      tester,
    ) async {
      await _showDialog(tester, readyToInstall: true);
      final visible = _visible(tester);
      expect(visible, contains(AppUpdateTexts.readyTitle.bn));
      expect(visible, contains(AppUpdateTexts.readyMessage.bn));
      expect(visible, contains(AppUpdateTexts.restartAndInstall.bn));
      expect(visible, isNot(contains(AppUpdateTexts.updateNow.bn)));
    });

    testWidgets('only one prompt is shown at a time', (tester) async {
      await _showDialog(tester);
      // The launch check and a finished download can both ask at once.
      final context = tester.element(find.text('open'));
      unawaited(showAppUpdateDialog(context));
      await tester.pumpAndSettle();
      expect(find.text(AppUpdateTexts.title.bn!), findsOneWidget);
    });
  });
}
