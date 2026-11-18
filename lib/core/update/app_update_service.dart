import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

import 'app_update_mock.dart';
import 'app_update_source.dart';

/// The outcome of asking Google Play to begin or resume an update.
enum AppUpdateFlowResult {
  /// Nothing was started: Play has no update, cannot answer, the platform is
  /// unsupported, or the launch check has already run.
  none,

  /// Play accepted the update flow and the downloaded update was handed back
  /// to Play for installation.
  started,

  /// The user cancelled Google Play's native confirmation dialog.
  canceled,

  /// Google Play could not download or install the update.
  failed,
}

/// Google Play *flexible* in-app updates: the new build downloads while the
/// user carries on in the app, then Play installs it once the download has
/// completed.
///
/// Play only answers these calls for a build it installed itself, so on a
/// debug or sideloaded build the check reports nothing (or fails) and the app
/// behaves exactly as it did before. iOS has no equivalent API, so the whole
/// flow is skipped there. To drive the flow anyway - from a local run or a
/// test - stand Play in with [AppUpdateMock].
class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  /// The one door the mock can come through, and it is bolted shut at
  /// compile time outside a debug build: [AppUpdateMock.debugOnly] is
  /// [kDebugMode], so in a release build this is `return null` and
  /// everything below it - the mock, and every class it drags in - is
  /// unreachable code the compiler drops. Production always gets
  /// [PlayUpdateSource]. Guarded by `app_update_release_safety_test.dart`.
  AppUpdateSource? get _mockSource {
    if (!AppUpdateMock.debugOnly) return null;
    return AppUpdateMock.enabled ? AppUpdateMock.source : null;
  }

  /// Google Play - or, on a debug run only, the mock standing in for it.
  AppUpdateSource get _source => _mockSource ?? const PlayUpdateSource();

  /// How often Play is re-asked about a download that was already running
  /// when the app started, and for how long - see [_followExistingDownload].
  static const _resumedPollInterval = Duration(seconds: 5);
  static const _resumedPollLimit = Duration(minutes: 3);

  /// Where the Google Play update has got to. It stays
  /// [InstallStatus.unknown] until a download starts or one is found already
  /// running.
  final ValueNotifier<InstallStatus> status = ValueNotifier(
    InstallStatus.unknown,
  );

  StreamSubscription<InstallStatus>? _statusSubscription;
  Timer? _resumedPollTimer;
  bool _installing = false;

  /// The check runs once per launch: Home is rebuilt every time the user
  /// comes back to it, and re-asking Play each time would re-open the prompt.
  bool _checkedThisLaunch = false;

  AppUpdateInfo? _info;

  /// Whether in-app updates exist on this platform at all. A debug run with
  /// the mock on acts as though they do, wherever it runs.
  bool get isSupported =>
      _mockSource != null || (!kIsWeb && Platform.isAndroid);

  /// Whether a download is running right now.
  bool get isDownloading =>
      status.value == InstallStatus.pending ||
      status.value == InstallStatus.downloading;

  /// Asks Google Play once per launch and immediately starts its native
  /// flexible-update flow when an update is available. There is deliberately
  /// no app-owned confirmation dialog before [InAppUpdate.startFlexibleUpdate].
  Future<AppUpdateFlowResult> checkAndStartUpdate() async {
    if (!isSupported || _checkedThisLaunch) return AppUpdateFlowResult.none;
    _checkedThisLaunch = true;

    final result = await _checkAndStart();
    if (kDebugMode) {
      final scenario = AppUpdateMock.scenario;
      final source = scenario == null ? 'play' : 'mock:${scenario.name}';
      debugPrint('[AppUpdate] $source -> ${result.name}');
    }
    return result;
  }

  Future<AppUpdateFlowResult> _checkAndStart() async {
    final info = await _checkForUpdate();
    if (info == null) return AppUpdateFlowResult.none;

    // Play reports a download it is already carrying out through
    // `installStatus`, whatever it says about availability, so this is read
    // before the availability check: there is nothing to offer downloading
    // when it is downloaded, or under way, already.
    switch (info.installStatus) {
      // Downloaded on an earlier run and never installed: hand it straight
      // back to Play to finish installing.
      case InstallStatus.downloaded:
        status.value = InstallStatus.downloaded;
        return await _completeDownloadedUpdate()
            ? AppUpdateFlowResult.started
            : AppUpdateFlowResult.failed;
      case InstallStatus.pending:
      case InstallStatus.downloading:
      case InstallStatus.installing:
        status.value = info.installStatus;
        _followExistingDownload();
        return AppUpdateFlowResult.none;
      case InstallStatus.unknown:
      case InstallStatus.installed:
      case InstallStatus.failed:
      case InstallStatus.canceled:
        break;
    }

    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return AppUpdateFlowResult.none;
    }
    // Play can rule a flexible update out (a very stale client, say); without
    // its consent there is no background download to start.
    if (!info.flexibleUpdateAllowed) return AppUpdateFlowResult.none;
    return _startFlexibleUpdate();
  }

  /// Starts the background download behind Google Play's native confirmation
  /// dialog, then completes the update once it is downloaded.
  Future<AppUpdateFlowResult> _startFlexibleUpdate() async {
    if (!isSupported || isDownloading) return AppUpdateFlowResult.none;

    _listenForDownload();
    status.value = InstallStatus.pending;
    try {
      final result = await _source.startFlexibleUpdate();
      switch (result) {
        // Play only resolves this once the download has finished, so the
        // update is ready to install even if no progress event arrived.
        case AppUpdateResult.success:
          status.value = InstallStatus.downloaded;
          return await _completeDownloadedUpdate()
              ? AppUpdateFlowResult.started
              : AppUpdateFlowResult.failed;
        case AppUpdateResult.userDeniedUpdate:
          status.value = InstallStatus.canceled;
          return AppUpdateFlowResult.canceled;
        case AppUpdateResult.inAppUpdateFailed:
          status.value = InstallStatus.failed;
          return AppUpdateFlowResult.failed;
      }
    } catch (error) {
      _log('startFlexibleUpdate failed', error);
      status.value = InstallStatus.failed;
      return AppUpdateFlowResult.failed;
    }
  }

  /// Hands a downloaded update to Play for installation. On a device the app
  /// is replaced, so a successful call normally never returns.
  Future<bool> _completeDownloadedUpdate() async {
    if (!isSupported || _installing) return _installing;
    // Play reports the install through the same channel as the download.
    _listenForDownload();
    _installing = true;
    status.value = InstallStatus.installing;
    try {
      await _source.completeFlexibleUpdate();
      if (status.value != InstallStatus.installed) {
        status.value = InstallStatus.installed;
      }
      return true;
    } catch (error) {
      _log('completeFlexibleUpdate failed', error);
      status.value = InstallStatus.failed;
      return false;
    } finally {
      _installing = false;
    }
  }

  /// Forgets that the check has run (and any download it saw), so the next
  /// [checkAndStartUpdate] asks again. For driving the flow repeatedly from a
  /// debug run or a test; see [AppUpdateMock].
  @visibleForTesting
  void reset() {
    _checkedThisLaunch = false;
    _info = null;
    _resumedPollTimer?.cancel();
    _resumedPollTimer = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _installing = false;
    status.value = InstallStatus.unknown;
  }

  Future<AppUpdateInfo?> _checkForUpdate() async {
    try {
      _info = await _source.checkForUpdate();
      return _info;
    } catch (error) {
      // Expected off the Play track (debug builds, sideloaded APKs) and
      // whenever Play is unreachable: there is simply no update to offer.
      _log('checkForUpdate failed', error);
      return null;
    }
  }

  void _listenForDownload() {
    _statusSubscription ??= _source.installUpdateListener.listen(
      (value) => status.value = value,
      onError: (Object error) {
        _log('install status stream failed', error);
        status.value = InstallStatus.failed;
      },
    );
  }

  /// Follows a download that Play started before this launch.
  ///
  /// Play only streams progress to the request that started it, and that
  /// request belongs to the run that is now gone - so the only way to see
  /// this one finish is to ask again. Polling stops as soon as it does (and a
  /// downloaded update is handed to Play for installation), and gives up after
  /// [_resumedPollLimit] rather than asking for the rest of the session.
  void _followExistingDownload() {
    if (_resumedPollTimer != null) return;
    final startedAt = DateTime.now();
    _resumedPollTimer = Timer.periodic(_resumedPollInterval, (timer) async {
      if (DateTime.now().difference(startedAt) > _resumedPollLimit) {
        timer.cancel();
        _resumedPollTimer = null;
        return;
      }
      final info = await _checkForUpdate();
      if (info == null) return;
      status.value = info.installStatus;
      switch (info.installStatus) {
        case InstallStatus.pending:
        case InstallStatus.downloading:
        case InstallStatus.installing:
          return;
        case InstallStatus.downloaded:
          unawaited(_completeDownloadedUpdate());
        case InstallStatus.installed:
        case InstallStatus.failed:
        case InstallStatus.canceled:
        case InstallStatus.unknown:
          timer.cancel();
          _resumedPollTimer = null;
      }
    });
  }

  void _log(String message, Object error) {
    if (kDebugMode) {
      debugPrint('[AppUpdate] $message: $error');
    }
  }
}
