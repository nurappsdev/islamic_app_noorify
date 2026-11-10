import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

import 'app_update_source.dart';

/// The situation the mock plays out.
enum AppUpdateMockScenario {
  /// An update is waiting to be downloaded: the whole flow, from the prompt
  /// through the download to the restart.
  available,

  /// Play has nothing newer - no prompt at all.
  none,

  /// An update downloaded on an earlier run and never installed: the app
  /// opens straight on the restart step.
  alreadyDownloaded,

  /// A download that was already running when the app started, which the
  /// service has to follow by asking Play again.
  downloadInProgress,

  /// Play accepts the request and then fails the download.
  downloadFails,

  /// The user turns Play's consent sheet down.
  userDenies,
}

/// Stands in for Google Play so the update flow can be driven from a local
/// run.
///
/// **Debug builds only, enforced at compile time.** [debugOnly] is
/// [kDebugMode], which the compiler knows to be `false` in a profile or
/// release build; every door into this class is shut behind it, so a release
/// build cannot be talked into mocking by a `--dart-define`, by calling
/// [enable], or by anything else. With the condition constant, the compiler
/// also drops the unreachable branches - and with them [MockUpdateSource] -
/// from the binary it emits. [AppUpdateService] reads it through a single
/// guarded getter, and `app_update_release_safety_test.dart` holds all of
/// that in place.
///
/// Turn it on without touching code:
///
/// ```sh
/// flutter run --dart-define=MOCK_APP_UPDATE=available
/// ```
///
/// `MOCK_APP_UPDATE` takes any [AppUpdateMockScenario] name (`true` is read
/// as `available`), and from a test or a debug entry point [enable] does the
/// same thing.
class AppUpdateMock {
  const AppUpdateMock._();

  /// Whether standing in for Play is permitted at all: true in a debug
  /// build, a compile-time `false` anywhere else.
  static const bool debugOnly = kDebugMode;

  /// `--dart-define=MOCK_APP_UPDATE=<scenario>`, read only by a debug build.
  /// In release this is a constant empty string: the define never reaches
  /// the compiled app, whatever it is set to.
  static const String _define = debugOnly
      ? String.fromEnvironment('MOCK_APP_UPDATE')
      : '';

  static AppUpdateMockScenario? _scenario = _scenarioFromDefine(_define);
  static MockUpdateSource? _source;

  /// Whether Play is being stood in for. A compile-time `false` outside a
  /// debug build.
  static bool get enabled => debugOnly && _scenario != null;

  /// The scenario in play, or null when the mock is off.
  static AppUpdateMockScenario? get scenario => enabled ? _scenario : null;

  /// The stand-in itself, built on first use. Only reachable while
  /// [enabled].
  static MockUpdateSource get source {
    assert(enabled, 'AppUpdateMock.source read while the mock is off.');
    return _source ??= MockUpdateSource(scenario: _scenario!);
  }

  /// Turns the mock on for [scenario] (and, with [downloadDuration], decides
  /// how long its download takes). Call it before the first update check -
  /// `main()`, a test's `setUp`, or a debug menu.
  ///
  /// Does nothing outside a debug build.
  static void enable(
    AppUpdateMockScenario scenario, {
    Duration downloadDuration = const Duration(seconds: 6),
    Duration latency = const Duration(milliseconds: 400),
    int versionCode = 999,
  }) {
    // Constant `false` in release: the compiler drops everything below.
    if (!debugOnly) return;
    _scenario = scenario;
    _source?.dispose();
    _source = MockUpdateSource(
      scenario: scenario,
      downloadDuration: downloadDuration,
      latency: latency,
      versionCode: versionCode,
    );
  }

  /// Hands the app back to the real Google Play.
  static void disable() {
    _scenario = null;
    _source?.dispose();
    _source = null;
  }

  static AppUpdateMockScenario? _scenarioFromDefine(String value) {
    if (!debugOnly) return null;
    final name = value.trim().toLowerCase();
    if (name.isEmpty || name == 'false' || name == 'off') return null;
    if (name == 'true' || name == 'on') return AppUpdateMockScenario.available;
    for (final scenario in AppUpdateMockScenario.values) {
      if (scenario.name.toLowerCase() == name) return scenario;
    }
    assert(false, 'Unknown MOCK_APP_UPDATE scenario "$value".');
    return null;
  }
}

/// An [AppUpdateSource] that plays out an [AppUpdateMockScenario] instead of
/// calling Google Play.
class MockUpdateSource implements AppUpdateSource {
  MockUpdateSource({
    required this.scenario,
    this.downloadDuration = const Duration(seconds: 6),
    this.latency = const Duration(milliseconds: 400),
    this.versionCode = 999,
  });

  final AppUpdateMockScenario scenario;

  /// How long the pretend download takes, start to finish.
  final Duration downloadDuration;

  /// How long each pretend Play call takes to answer.
  final Duration latency;

  /// The version code the mock offers, as `availableVersionCode`.
  final int versionCode;

  final StreamController<InstallStatus> _states =
      StreamController<InstallStatus>.broadcast();

  InstallStatus _installStatus = InstallStatus.unknown;

  /// When the [AppUpdateMockScenario.downloadInProgress] download started -
  /// the first check the app makes, since that stands for a download begun
  /// before this run.
  DateTime? _resumedAt;

  @override
  Stream<InstallStatus> get installUpdateListener => _states.stream;

  @override
  Future<AppUpdateInfo> checkForUpdate() async {
    await Future<void>.delayed(latency);
    if (scenario == AppUpdateMockScenario.alreadyDownloaded) {
      _installStatus = InstallStatus.downloaded;
    }
    if (scenario == AppUpdateMockScenario.downloadInProgress) {
      final startedAt = _resumedAt ??= DateTime.now();
      _installStatus =
          DateTime.now().difference(startedAt) >= downloadDuration
          ? InstallStatus.downloaded
          : InstallStatus.downloading;
    }
    return _info();
  }

  @override
  Future<AppUpdateResult> startFlexibleUpdate() async {
    // Play's consent sheet.
    await Future<void>.delayed(latency);
    switch (scenario) {
      case AppUpdateMockScenario.userDenies:
        return AppUpdateResult.userDeniedUpdate;
      case AppUpdateMockScenario.downloadFails:
        _emit(InstallStatus.pending);
        await Future<void>.delayed(downloadDuration ~/ 2);
        _emit(InstallStatus.failed);
        return AppUpdateResult.inAppUpdateFailed;
      case AppUpdateMockScenario.available:
      case AppUpdateMockScenario.none:
      case AppUpdateMockScenario.alreadyDownloaded:
      case AppUpdateMockScenario.downloadInProgress:
        break;
    }

    _emit(InstallStatus.pending);
    await Future<void>.delayed(downloadDuration ~/ 4);
    _emit(InstallStatus.downloading);
    await Future<void>.delayed(downloadDuration - (downloadDuration ~/ 4));
    _emit(InstallStatus.downloaded);
    // Play resolves the request only once the download is done.
    return AppUpdateResult.success;
  }

  @override
  Future<void> completeFlexibleUpdate() async {
    await Future<void>.delayed(latency);
    _emit(InstallStatus.installing);
    await Future<void>.delayed(latency);
    // The real Play replaces the running app here, so nothing past this point
    // is ever seen on a device; the mock reports it instead, and the dialog
    // closes itself.
    _emit(InstallStatus.installed);
  }

  void dispose() => _states.close();

  void _emit(InstallStatus status) {
    _installStatus = status;
    if (!_states.isClosed) _states.add(status);
  }

  AppUpdateInfo _info() {
    final availability = switch (scenario) {
      AppUpdateMockScenario.none => UpdateAvailability.updateNotAvailable,
      AppUpdateMockScenario.alreadyDownloaded ||
      AppUpdateMockScenario.downloadInProgress =>
        UpdateAvailability.developerTriggeredUpdateInProgress,
      AppUpdateMockScenario.available ||
      AppUpdateMockScenario.downloadFails ||
      AppUpdateMockScenario.userDenies => UpdateAvailability.updateAvailable,
    };
    return AppUpdateInfo(
      updateAvailability: availability,
      immediateUpdateAllowed: true,
      immediateAllowedPreconditions: null,
      flexibleUpdateAllowed: true,
      flexibleAllowedPreconditions: null,
      availableVersionCode: versionCode,
      installStatus: _installStatus,
      packageName: 'com.tuhfatulmuslim.app',
      clientVersionStalenessDays: 1,
      updatePriority: 3,
    );
  }
}
