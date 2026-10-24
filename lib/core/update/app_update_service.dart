import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

import 'app_update_mock.dart';
import 'app_update_reminder.dart';
import 'app_update_source.dart';

/// What the launch check found, and so which prompt (if any) to show.
enum AppUpdatePrompt {
  /// Nothing to show: no update, Play could not answer, a download is already
  /// running, or the user put this build off less than
  /// [AppUpdateReminder.reminderInterval] ago.
  none,

  /// An update is waiting to be downloaded - show the update dialog.
  available,

  /// A download that finished earlier was never installed - offer the restart.
  readyToInstall,
}

/// Google Play *flexible* in-app updates: the new build downloads while the
/// user carries on in the app, and is installed by a restart they ask for.
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

  /// Where the download has got to, for the dialog and [AppUpdateWatcher] to
  /// follow. It stays [InstallStatus.unknown] until a download starts or one
  /// is found already running.
  final ValueNotifier<InstallStatus> status = ValueNotifier(
    InstallStatus.unknown,
  );

  StreamSubscription<InstallStatus>? _statusSubscription;
  Timer? _resumedPollTimer;

  /// The check runs once per launch: Home is rebuilt every time the user
  /// comes back to it, and re-asking Play each time would re-open the prompt.
  bool _checkedThisLaunch = false;

  AppUpdateInfo? _info;

  /// Play's version code for the update on offer, as of the last check.
  int? get availableVersionCode => _info?.availableVersionCode;

  /// Whether in-app updates exist on this platform at all. A debug run with
  /// the mock on acts as though they do, wherever it runs.
  bool get isSupported => _mockSource != null || Platform.isAndroid;

  /// Whether a download is running right now.
  bool get isDownloading =>
      status.value == InstallStatus.pending ||
      status.value == InstallStatus.downloading;

  /// Asks Play, once per launch, whether a flexible update is waiting.
  Future<AppUpdatePrompt> checkOnLaunch() async {
    if (!isSupported || _checkedThisLaunch) return AppUpdatePrompt.none;
    _checkedThisLaunch = true;

    final prompt = await _resolveLaunchPrompt();
    if (kDebugMode) {
      final scenario = AppUpdateMock.scenario;
      final source = scenario == null ? 'play' : 'mock:${scenario.name}';
      debugPrint('[AppUpdate] $source -> ${prompt.name}');
    }
    return prompt;
  }

  Future<AppUpdatePrompt> _resolveLaunchPrompt() async {
    final info = await _checkForUpdate();
    if (info == null) return AppUpdatePrompt.none;

    // Play reports a download it is already carrying out through
    // `installStatus`, whatever it says about availability, so this is read
    // before the availability check: there is nothing to offer downloading
    // when it is downloaded, or under way, already.
    switch (info.installStatus) {
      // Downloaded on an earlier run and never installed: only the restart
      // is left to offer.
      case InstallStatus.downloaded:
        status.value = InstallStatus.downloaded;
        return AppUpdatePrompt.readyToInstall;
      case InstallStatus.pending:
      case InstallStatus.downloading:
      case InstallStatus.installing:
        status.value = info.installStatus;
        _followExistingDownload();
        return AppUpdatePrompt.none;
      case InstallStatus.unknown:
      case InstallStatus.installed:
      case InstallStatus.failed:
      case InstallStatus.canceled:
        break;
    }

    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return AppUpdatePrompt.none;
    }
    // Play can rule a flexible update out (a very stale client, say); without
    // its consent there is no background download to offer.
    if (!info.flexibleUpdateAllowed) return AppUpdatePrompt.none;
    if (await AppUpdateReminder.isSnoozed(info.availableVersionCode)) {
      return AppUpdatePrompt.none;
    }
    return AppUpdatePrompt.available;
  }

  /// Starts the background download, behind Play's own consent sheet.
  ///
  /// [status] reports the download's progress from here on. The returned
  /// future is Play's: it resolves with [AppUpdateResult.success] only once
  /// the download has finished, and earlier than that if the user turns the
  /// consent sheet down or the download fails.
  Future<AppUpdateResult> startDownload() async {
    if (!isSupported) return AppUpdateResult.inAppUpdateFailed;
    // Play registers a fresh progress listener per request, so asking twice
    // would report every step of one download twice over.
    if (isDownloading) return AppUpdateResult.success;

    _listenForDownload();
    status.value = InstallStatus.pending;
    try {
      final result = await _source.startFlexibleUpdate();
      switch (result) {
        // Play only resolves this once the download has finished, so the
        // update is ready to install even if no progress event arrived.
        case AppUpdateResult.success:
          status.value = InstallStatus.downloaded;
        case AppUpdateResult.userDeniedUpdate:
          status.value = InstallStatus.canceled;
        case AppUpdateResult.inAppUpdateFailed:
          status.value = InstallStatus.failed;
      }
      return result;
    } catch (error) {
      _log('startFlexibleUpdate failed', error);
      status.value = InstallStatus.failed;
      return AppUpdateResult.inAppUpdateFailed;
    }
  }

  /// Restarts the app into the downloaded update.
  ///
  /// On success the app is replaced and this future never returns, so only a
  /// `false` - Play refusing to install - is worth acting on.
  Future<bool> install() async {
    if (!isSupported) return false;
    // Play reports the install through the same channel as the download.
    _listenForDownload();
    try {
      await _source.completeFlexibleUpdate();
      return true;
    } catch (error) {
      _log('completeFlexibleUpdate failed', error);
      status.value = InstallStatus.failed;
      return false;
    }
  }

  /// Puts the prompt off for [AppUpdateReminder.reminderInterval].
  Future<void> remindLater() => AppUpdateReminder.snooze(availableVersionCode);

  /// Forgets that the check has run (and any download it saw), so the next
  /// [checkOnLaunch] asks again. For driving the flow repeatedly from a debug
  /// run or a test; see [AppUpdateMock].
  @visibleForTesting
  void reset() {
    _checkedThisLaunch = false;
    _info = null;
    _resumedPollTimer?.cancel();
    _resumedPollTimer = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;
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
  /// this one finish is to ask again. Polling stops as soon as it does (the
  /// restart is then offered), and gives up after [_resumedPollLimit] rather
  /// than asking for the rest of the session.
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
