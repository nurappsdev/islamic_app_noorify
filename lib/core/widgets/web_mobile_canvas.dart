import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Keeps existing mobile-first routes readable on a browser until each route
/// receives its own desktop layout. Full-width Web routes deliberately skip
/// this wrapper (currently Splash and Onboarding only).
class WebMobileCanvas extends StatelessWidget {
  const WebMobileCanvas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    final media = MediaQuery.of(context);
    final width = media.size.width.clamp(0.0, 600.0).toDouble();
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: MediaQuery(
            data: media.copyWith(size: Size(width, media.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}
