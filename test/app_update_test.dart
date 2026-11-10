import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:tuhfatul_muslim/core/update/app_update_mock.dart';
import 'package:tuhfatul_muslim/core/update/app_update_reminder.dart';
import 'package:tuhfatul_muslim/core/update/app_update_service.dart';
import 'package:tuhfatul_muslim/core/update/app_update_watcher.dart';
import 'package:tuhfatul_muslim/core/update/app_update_texts.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/core/widgets/app_update_dialog.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Stages a "Later" chosen [daysAgo] days ago, so the three-day rule can be
/// checked without waiting for the clock.
Future<void> _stageSnooze(double daysAgo, {int? versionCode}) async {
  SharedPreferences.setMockInitialValues({});
  await AppUpdateReminder.snoozeDaysAgo(daysAgo, versionCode: versionCode);
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
      await _stageSnooze(2.95, versionCode: 8);
      expect(await AppUpdateReminder.isSnoozed(8), isTrue);

      await _stageSnooze(3.05, versionCode: 8);
      expect(await AppUpdateReminder.isSnoozed(8), isFalse);
    });

    test('a newer release is offered without waiting', () async {
      await _stageSnooze(0.05, versionCode: 8);
      expect(await AppUpdateReminder.isSnoozed(9), isFalse);
      expect(await AppUpdateReminder.isSnoozed(8), isTrue);
      // An older build on offer is the one that was put off, or older still.
      expect(await AppUpdateReminder.isSnoozed(7), isTrue);
    });

    test('a clock set backwards does not hide the prompt', () async {
      await _stageSnooze(-2, versionCode: 8);
      expect(await AppUpdateReminder.isSnoozed(8), isFalse);
    });

    test('clear forgets the postponement', () async {
      await _stageSnooze(0.05, versionCode: 8);
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

  group('AppUpdateService, with Play mocked out', () {
    final service = AppUpdateService.instance;

    setUp(() => SharedPreferences.setMockInitialValues({}));

    tearDown(() {
      service.reset();
      AppUpdateMock.disable();
    });

    void mock(
      AppUpdateMockScenario scenario, {
      Duration downloadDuration = const Duration(milliseconds: 400),
    }) => AppUpdateMock.enable(
      scenario,
      downloadDuration: downloadDuration,
      latency: const Duration(milliseconds: 20),
      versionCode: 9,
    );

    test('nothing is offered when Play has nothing newer', () async {
      mock(AppUpdateMockScenario.none);
      expect(await service.checkOnLaunch(), AppUpdatePrompt.none);
    });

    test('an available update is offered', () async {
      mock(AppUpdateMockScenario.available);
      expect(await service.checkOnLaunch(), AppUpdatePrompt.available);
      expect(service.availableVersionCode, 9);
    });

    test('an update downloaded earlier goes straight to the restart', () async {
      mock(AppUpdateMockScenario.alreadyDownloaded);
      expect(await service.checkOnLaunch(), AppUpdatePrompt.readyToInstall);
      expect(service.status.value, InstallStatus.downloaded);
    });

    test('a download already running is followed, not re-offered', () async {
      mock(
        AppUpdateMockScenario.downloadInProgress,
        downloadDuration: const Duration(minutes: 1),
      );
      expect(await service.checkOnLaunch(), AppUpdatePrompt.none);
      expect(service.status.value, InstallStatus.downloading);
    });

    test('Play is asked once per launch', () async {
      mock(AppUpdateMockScenario.available);
      expect(await service.checkOnLaunch(), AppUpdatePrompt.available);
      expect(await service.checkOnLaunch(), AppUpdatePrompt.none);
    });

    test('a Later from yesterday keeps the prompt away', () async {
      mock(AppUpdateMockScenario.available);
      await _stageSnooze(1, versionCode: 9);
      expect(await service.checkOnLaunch(), AppUpdatePrompt.none);
    });

    test('a Later from over three days ago lets it through', () async {
      mock(AppUpdateMockScenario.available);
      await _stageSnooze(3.05, versionCode: 9);
      expect(await service.checkOnLaunch(), AppUpdatePrompt.available);
    });

    test('a Later on an older build does not cover this one', () async {
      mock(AppUpdateMockScenario.available);
      await _stageSnooze(1, versionCode: 8);
      expect(await service.checkOnLaunch(), AppUpdatePrompt.available);
    });

    test('the download reports its way through to downloaded', () async {
      mock(AppUpdateMockScenario.available);
      await service.checkOnLaunch();

      final seen = <InstallStatus>[];
      void record() => seen.add(service.status.value);
      service.status.addListener(record);
      addTearDown(() => service.status.removeListener(record));

      expect(await service.startDownload(), AppUpdateResult.success);
      expect(seen.first, InstallStatus.pending);
      expect(seen, contains(InstallStatus.downloading));
      expect(service.status.value, InstallStatus.downloaded);
    });

    test('a denied consent sheet leaves nothing downloading', () async {
      mock(AppUpdateMockScenario.userDenies);
      await service.checkOnLaunch();
      expect(await service.startDownload(), AppUpdateResult.userDeniedUpdate);
      expect(service.status.value, InstallStatus.canceled);
      expect(service.isDownloading, isFalse);
    });

    test('a failed download is reported as failed', () async {
      mock(AppUpdateMockScenario.downloadFails);
      await service.checkOnLaunch();
      expect(
        await service.startDownload(),
        AppUpdateResult.inAppUpdateFailed,
      );
      expect(service.status.value, InstallStatus.failed);
    });

    test('one download at a time', () async {
      mock(AppUpdateMockScenario.available);
      await service.checkOnLaunch();
      final first = service.startDownload();
      // Play registers a progress listener per request, so a second request
      // would report every step of this one twice over.
      expect(await service.startDownload(), AppUpdateResult.success);
      expect(await first, AppUpdateResult.success);
    });

    test('installing restarts into the update', () async {
      mock(AppUpdateMockScenario.alreadyDownloaded);
      await service.checkOnLaunch();
      expect(await service.install(), isTrue);
    });

    test('the mock never stands in for Play in a release build', () {
      // kDebugMode is true under `flutter test`, so this only pins the
      // intent: the gate is on the flag, not on the scenario alone.
      mock(AppUpdateMockScenario.available);
      expect(AppUpdateMock.enabled, isTrue);
      AppUpdateMock.disable();
      expect(AppUpdateMock.enabled, isFalse);
      expect(AppUpdateMock.scenario, isNull);
    });
  });

  group('AppUpdateWatcher on the real route stack', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AppUpdateMock.enable(
        AppUpdateMockScenario.available,
        downloadDuration: const Duration(milliseconds: 400),
        latency: const Duration(milliseconds: 20),
      );
    });

    tearDown(() {
      AppUpdateService.instance.reset();
      AppUpdateMock.disable();
    });

    /// The app's own start-up shape: `initialRoute: '/splash'` makes Flutter
    /// build the stack `['/', '/splash']`, so Home is mounted underneath the
    /// splash before the splash replaces itself with Home.
    Future<void> pumpAppFromSplash(WidgetTester tester) async {
      tester.view.physicalSize = const Size(375 * 2, 812 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final bloc = LanguageBloc(
        initialLanguage: AppLanguage.bangla,
        persist: (_) async {},
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              initialRoute: '/splash',
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => settings.name == '/splash'
                    ? Scaffold(
                        body: Center(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushReplacementNamed('/'),
                            child: const Text('leave splash'),
                          ),
                        ),
                      )
                    : const AppUpdateWatcher(
                        child: Scaffold(body: Center(child: Text('home'))),
                      ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the Home buried under the splash prompts nothing', (
      tester,
    ) async {
      await pumpAppFromSplash(tester);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(AppUpdateTexts.title.bn!), findsNothing);
    });

    testWidgets('and leaves the check for the Home the user actually sees', (
      tester,
    ) async {
      await pumpAppFromSplash(tester);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('leave splash'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('home'), findsOneWidget);
      expect(find.text(AppUpdateTexts.title.bn!), findsOneWidget);
      expect(find.text(AppUpdateTexts.updateNow.bn!), findsOneWidget);
    });
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

    testWidgets('walks from Update Now through the download to the restart', (
      tester,
    ) async {
      AppUpdateMock.enable(
        AppUpdateMockScenario.available,
        downloadDuration: const Duration(milliseconds: 400),
        latency: const Duration(milliseconds: 20),
      );
      addTearDown(() {
        AppUpdateService.instance.reset();
        AppUpdateMock.disable();
      });
      await _showDialog(tester);

      await tester.tap(find.text(AppUpdateTexts.updateNow.bn!));
      await tester.pump();
      // The download is under way: the card says so and offers nothing but
      // getting out of its way.
      expect(_visible(tester), contains(AppUpdateTexts.downloadingTitle.bn));
      expect(_visible(tester), contains(AppUpdateTexts.keepBrowsing.bn));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      expect(_visible(tester), contains(AppUpdateTexts.readyTitle.bn));
      expect(_visible(tester), contains(AppUpdateTexts.restartAndInstall.bn));

      await tester.tap(find.text(AppUpdateTexts.restartAndInstall.bn!));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      // Play has replaced the app by this point on a device; the mock closes
      // the card instead.
      expect(find.text(AppUpdateTexts.readyTitle.bn!), findsNothing);
      expect(isAppUpdateDialogVisible, isFalse);
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
