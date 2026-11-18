import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';

import 'package:tuhfatul_muslim/core/update/app_update_mock.dart';
import 'package:tuhfatul_muslim/core/update/app_update_service.dart';
import 'package:tuhfatul_muslim/core/update/app_update_watcher.dart';

void main() {
  final service = AppUpdateService.instance;

  setUp(() {
    service.reset();
    AppUpdateMock.disable();
  });

  tearDown(() {
    service.reset();
    AppUpdateMock.disable();
  });

  void mock(AppUpdateMockScenario scenario) => AppUpdateMock.enable(
    scenario,
    downloadDuration: const Duration(milliseconds: 20),
    latency: const Duration(milliseconds: 5),
    versionCode: 9,
  );

  group('AppUpdateService', () {
    test('does nothing when Google Play has no newer version', () async {
      mock(AppUpdateMockScenario.none);

      expect(await service.checkAndStartUpdate(), AppUpdateFlowResult.none);
      expect(service.status.value, InstallStatus.unknown);
    });

    test(
      'starts Google Play directly and installs the downloaded update',
      () async {
        mock(AppUpdateMockScenario.available);

        expect(
          await service.checkAndStartUpdate(),
          AppUpdateFlowResult.started,
        );
        expect(service.status.value, InstallStatus.installed);
      },
    );

    test('keeps a native-dialog cancellation as a cancellation', () async {
      mock(AppUpdateMockScenario.userDenies);

      expect(await service.checkAndStartUpdate(), AppUpdateFlowResult.canceled);
      expect(service.status.value, InstallStatus.canceled);
    });

    test('reports a Google Play download failure', () async {
      mock(AppUpdateMockScenario.downloadFails);

      expect(await service.checkAndStartUpdate(), AppUpdateFlowResult.failed);
      expect(service.status.value, InstallStatus.failed);
    });

    test('does not trigger Google Play twice in one launch', () async {
      mock(AppUpdateMockScenario.available);

      expect(await service.checkAndStartUpdate(), AppUpdateFlowResult.started);
      expect(await service.checkAndStartUpdate(), AppUpdateFlowResult.none);
    });

    test('installs an update that finished before the app resumed', () async {
      mock(AppUpdateMockScenario.alreadyDownloaded);

      expect(await service.checkAndStartUpdate(), AppUpdateFlowResult.started);
      expect(service.status.value, InstallStatus.installed);
    });

    test(
      'does not start a second flow while Play is already downloading',
      () async {
        mock(AppUpdateMockScenario.downloadInProgress);

        expect(await service.checkAndStartUpdate(), AppUpdateFlowResult.none);
        expect(service.status.value, InstallStatus.downloading);
      },
    );
  });

  testWidgets('the watcher shows no app-owned update dialog', (tester) async {
    mock(AppUpdateMockScenario.available);

    await tester.pumpWidget(
      const MaterialApp(
        home: AppUpdateWatcher(
          child: Scaffold(body: Center(child: Text('home'))),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('home'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(service.status.value, InstallStatus.installed);
  });
}
