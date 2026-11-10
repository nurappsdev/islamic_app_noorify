import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import 'package:tuhfatul_muslim/core/constants/app_route_observer.dart';
import 'package:tuhfatul_muslim/core/update/app_update_service.dart';
import 'package:tuhfatul_muslim/core/widgets/app_update_dialog.dart';

/// Drives the flexible in-app update flow for the screen it wraps (Home, the
/// first screen of every launch): the check as soon as that screen appears,
/// and the "update ready" prompt whenever a download finishes afterwards -
/// including one the user left running in the background after dismissing the
/// dialog.
///
/// It adds nothing to the layout, and on a build Play knows nothing about
/// (debug, sideloaded) or on iOS the check finds nothing and no dialog is
/// ever shown. See [AppUpdateService].
class AppUpdateWatcher extends StatefulWidget {
  const AppUpdateWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateWatcher> createState() => _AppUpdateWatcherState();
}

class _AppUpdateWatcherState extends State<AppUpdateWatcher> with RouteAware {
  final AppUpdateService _service = AppUpdateService.instance;

  /// The restart is offered once per launch: the user who dismissed it is not
  /// asked again every time they come back to this screen.
  bool _offeredRestart = false;

  @override
  void initState() {
    super.initState();
    _service.status.addListener(_onStatusChanged);
    // Play is asked after the first frame, so the screen it prompts over is
    // already built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCheck());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _service.status.removeListener(_onStatusChanged);
    super.dispose();
  }

  /// Back on this screen: a download that finished while the user was
  /// elsewhere - where there was no prompting them - has a restart to offer.
  @override
  void didPopNext() {
    if (_offeredRestart) return;
    if (_service.status.value != InstallStatus.downloaded) return;
    _show(readyToInstall: true);
  }

  Future<void> _runCheck() async {
    if (!mounted) return;
    // This screen can be built *underneath* another one: Flutter turns an
    // `initialRoute` of `/splash` into the stack `['/', '/splash']`, so Home
    // exists, buried, from the first frame - and the splash later hands over
    // to a second copy of it. The buried one must not use up the
    // once-per-launch check, or the copy the user actually sees would find
    // it already spent and never prompt.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
      _log('check skipped: this screen is not the one on top');
      return;
    }
    final prompt = await _service.checkOnLaunch();
    switch (prompt) {
      case AppUpdatePrompt.none:
        return;
      case AppUpdatePrompt.available:
        await _show();
      case AppUpdatePrompt.readyToInstall:
        await _show(readyToInstall: true);
    }
  }

  void _onStatusChanged() {
    if (_service.status.value != InstallStatus.downloaded) return;
    // An open dialog moves itself on to the restart step; this is for the one
    // that was dismissed while the download carried on.
    if (isAppUpdateDialogVisible) return;
    _show(readyToInstall: true);
  }

  Future<void> _show({bool readyToInstall = false}) async {
    if (!mounted) {
      _log('skipped: the screen is gone');
      return;
    }
    // Something was pushed over this screen in the meantime - an alarm going
    // off at launch, or the user moving on to another module. Prompting on
    // top of it would bury what they are doing; [didPopNext] picks the
    // restart up when they are back, and the next launch checks again.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
      _log('prompt skipped: another screen is on top');
      return;
    }
    if (readyToInstall) _offeredRestart = true;
    _log('showing the prompt${readyToInstall ? ' (restart)' : ''}');
    await showAppUpdateDialog(context, readyToInstall: readyToInstall);
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[AppUpdate] $message');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
