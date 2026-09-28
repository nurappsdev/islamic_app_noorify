import 'package:flutter/material.dart';

import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_tracking_screen.dart';

/// Opens the Amol tracker from a Home card, focused on [section] and - when
/// given - on the exact item [itemKey] (`fajr`, `fajr_sunnah`, `sadaqah`, ...)
/// the user tapped.
///
/// The screen arrives with a short fade and slide, and only one tracker is ever
/// opened by this: taps that land while one is opening or open are ignored, so
/// a burst of taps can't stack screens.
Future<void> openAmolTracker(
  BuildContext context, {
  required AmalSection section,
  String? itemKey,
  @visibleForTesting WidgetBuilder? builder,
}) async {
  if (_AmolTrackerOpening.busy) return;
  _AmolTrackerOpening.busy = true;
  try {
    await Navigator.of(context).push<void>(
      _AmolTrackerRoute(
        builder:
            builder ??
            (_) => AmolTrackingScreen(
              selectedSection: section,
              selectedItemKey: itemKey,
            ),
      ),
    );
  } finally {
    _AmolTrackerOpening.busy = false;
  }
}

/// Whether a tracker opened from Home is on its way in or on screen.
class _AmolTrackerOpening {
  const _AmolTrackerOpening._();

  static bool busy = false;
}

/// A fade with a slight rise. Short enough to feel immediate, long enough that
/// the screen doesn't just appear.
class _AmolTrackerRoute extends PageRouteBuilder<void> {
  _AmolTrackerRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}
