import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/update/app_update_service.dart';

/// Drives the flexible in-app update flow for the screen it wraps (Home, the
/// first screen of every launch). The check runs as soon as that screen is
/// visible, and Google Play supplies the only update confirmation UI.
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

class _AppUpdateWatcherState extends State<AppUpdateWatcher> {
  final AppUpdateService _service = AppUpdateService.instance;

  @override
  void initState() {
    super.initState();
    // Play is asked after the first frame, so the screen it prompts over is
    // already built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCheck());
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
    await _service.checkAndStartUpdate();
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[AppUpdate] $message');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
