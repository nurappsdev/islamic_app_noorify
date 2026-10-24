import 'package:in_app_update/in_app_update.dart';

/// The Google Play calls [AppUpdateService] makes, behind an interface so a
/// debug build can stand in for them - Play itself only answers a build it
/// installed, which rules out testing the flow from a local run. See
/// `AppUpdateMock`.
abstract interface class AppUpdateSource {
  /// What Play says about the update on offer, and about any download of it
  /// already under way.
  Future<AppUpdateInfo> checkForUpdate();

  /// How far a running download has got.
  Stream<InstallStatus> get installUpdateListener;

  /// Asks for the download, behind Play's consent sheet. Resolves with
  /// [AppUpdateResult.success] only once the download has finished.
  Future<AppUpdateResult> startFlexibleUpdate();

  /// Restarts the app into the downloaded update.
  Future<void> completeFlexibleUpdate();
}

/// The real thing: the `in_app_update` plugin, talking to Google Play.
class PlayUpdateSource implements AppUpdateSource {
  const PlayUpdateSource();

  @override
  Future<AppUpdateInfo> checkForUpdate() => InAppUpdate.checkForUpdate();

  @override
  Stream<InstallStatus> get installUpdateListener =>
      InAppUpdate.installUpdateListener;

  @override
  Future<AppUpdateResult> startFlexibleUpdate() =>
      InAppUpdate.startFlexibleUpdate();

  @override
  Future<void> completeFlexibleUpdate() =>
      InAppUpdate.completeFlexibleUpdate();
}
