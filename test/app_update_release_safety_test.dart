import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:tuhfatul_muslim/core/update/app_update_mock.dart';
import 'package:tuhfatul_muslim/core/update/app_update_service.dart';

/// The mock that stands in for Google Play must never be reachable from a
/// release build. The gate is [AppUpdateMock.debugOnly] - a `const` equal to
/// `kDebugMode`, which the compiler folds to `false` when building for
/// profile or release - and these tests hold the shape of that gate in
/// place, so a later change cannot quietly open a door into production.

/// A Dart file's code, with its comments taken out: a mention of the mock in
/// a doc comment is documentation, not a way in.
String _code(String path) {
  final source = File(path).readAsStringSync();
  return source
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');
}

List<File> _dartFilesIn(String directory) => Directory(directory)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .toList();

void main() {
  const mockPath = 'lib/core/update/app_update_mock.dart';
  const servicePath = 'lib/core/update/app_update_service.dart';

  group('the mock cannot reach a release build', () {
    test('it is off unless a build asks for it', () {
      // Nothing has enabled it and no --dart-define was passed, which is how
      // every ordinary build - debug included - starts out.
      expect(AppUpdateMock.enabled, isFalse);
      expect(AppUpdateMock.scenario, isNull);
    });

    test('every door into it is bolted to kDebugMode', () {
      final code = _code(mockPath);
      // The gate itself.
      expect(
        code,
        contains('static const bool debugOnly = kDebugMode;'),
        reason: 'The mock must be gated on kDebugMode, and at compile time.',
      );
      // The --dart-define is read only by a debug build, so a release build
      // cannot be talked into mocking from the build command.
      expect(
        code,
        contains(
          "static const String _define = debugOnly\n"
          "      ? String.fromEnvironment('MOCK_APP_UPDATE')\n"
          "      : '';",
        ),
        reason: 'MOCK_APP_UPDATE must be read behind the debug gate.',
      );
      // Being enabled, and being switched on by hand, both run through it.
      expect(code, contains('static bool get enabled => debugOnly &&'));
      expect(code, contains('if (!debugOnly) return;'));
    });

    test('the service reaches it through one guarded getter only', () {
      final code = _code(servicePath);
      expect(
        code,
        contains(
          'AppUpdateSource? get _mockSource {\n'
          '    if (!AppUpdateMock.debugOnly) return null;',
        ),
        reason: 'The mock must sit behind a compile-time debug guard.',
      );
      expect(
        code,
        contains('AppUpdateSource get _source => _mockSource ?? const '
            'PlayUpdateSource();'),
        reason: 'Production must fall through to the real Play source.',
      );

      // Any other mention of the mock in the service is either inside that
      // getter or inside a kDebugMode block.
      final lines = code.split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('AppUpdateMock')) continue;
        final context = lines.sublist(i > 6 ? i - 6 : 0, i + 1).join('\n');
        expect(
          context,
          anyOf(contains('debugOnly'), contains('kDebugMode')),
          reason:
              'Unguarded mock reference in $servicePath line ${i + 1}: '
              '${lines[i].trim()}',
        );
      }
    });

    test('nothing else in the app knows the mock exists', () {
      final offenders = <String>[];
      for (final file in _dartFilesIn('lib')) {
        final path = file.path;
        if (path.endsWith('app_update_mock.dart')) continue;
        final code = _code(path);
        if (!code.contains('app_update_mock.dart') &&
            !code.contains('AppUpdateMock')) {
          continue;
        }
        if (!path.endsWith('app_update_service.dart')) offenders.add(path);
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'Only AppUpdateService may touch the mock, so there is one place '
            'to guard. Found: $offenders',
      );
    });

    test('the mock is never wired up at start-up', () {
      // `main()` enabling it would ship a mocked app the moment someone
      // built a release from the same source.
      expect(_code('lib/main.dart'), isNot(contains('AppUpdateMock')));
    });
  });

  group('with the mock off, the service talks only to Google Play', () {
    final service = AppUpdateService.instance;

    setUp(() {
      AppUpdateMock.disable();
      service.reset();
    });

    tearDown(() => service.reset());

    test('an unsupported platform offers nothing at all', () async {
      // These tests run on the host, where `Platform.isAndroid` is false, so
      // this is the real Play path reporting that it does not apply - no
      // mock standing in for it.
      expect(service.isSupported, isFalse);
      expect(await service.checkOnLaunch(), AppUpdatePrompt.none);
      expect(service.status.value, InstallStatus.unknown);
    });

    test('nothing can be downloaded or installed', () async {
      expect(await service.startDownload(), AppUpdateResult.inAppUpdateFailed);
      expect(await service.install(), isFalse);
      expect(service.isDownloading, isFalse);
    });
  });
}
