import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/utils/app_text.dart';
import '../utils/post_splash_route.dart';

class RamadanSplashScreen extends StatefulWidget {
  const RamadanSplashScreen({super.key});

  @override
  State<RamadanSplashScreen> createState() => _RamadanSplashScreenState();
}

class _RamadanSplashScreenState extends State<RamadanSplashScreen> {
  static const _splashDuration = Duration(seconds: 3);
  static const _backgroundImagePath = 'assets/splasImg.png';
  static const _logoImagePath = 'assets/appLogoFinal.png';
  static const _splashVerse =
      'তোমরা তোমাদের রবের অভিমুখী হও এবং তাঁর নিকট আত্মসমর্পণ কর তোমাদের নিকট শাস্তি আসার পূর্বে, অতঃপর তোমাদেরকে সাহায্য করা হবেনা।\n\n৩৯ : ৫৪';

  /// The splash artwork's own light tone, behind the image while it decodes
  /// and in its place if it ever fails to load.
  static const _splashBackground = Color(0xFFF8F8F4);

  @override
  void initState() {
    super.initState();
    _openNextAfterDelay();
  }

  Future<void> _openNextAfterDelay() async {
    await Future<void>.delayed(_splashDuration);
    if (!mounted) return;
    // Something (namely a cold-launched `AlarmRingingScreen` — see
    // `main.dart`) was pushed on top of this screen: `pushReplacement`
    // always replaces the navigator's current top route, not necessarily
    // the route that requested it, so without this guard our own delayed
    // redirect would silently swap out whatever got stacked above us.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    final nextRoute = await resolvePostSplashRoute();
    if (!mounted) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const _WebRamadanSplash();

    final appText = AppText.of(context);

    // Dark mode is not followed here: `assets/splasImg.png` is one fixed
    // light artwork in both themes, so the text over it keeps the dark
    // colors it was designed in — mapped to dark mode's light ink it turned
    // near-white on a light background and read as blank.
    return Scaffold(
      backgroundColor: _splashBackground,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _backgroundImagePath,
              key: const Key('opening_splash_image'),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(color: _splashBackground);
              },
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                child: Column(
                  children: [
                    const Spacer(flex: 11),
                    Image.asset(
                      _logoImagePath,
                      width: 112.w,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          appText.tuhfatulMuslim,
                          style: TextStyle(
                            color: const Color(0xFF7D8765),
                            fontSize: 30.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      appText.tuhfatulMuslim,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF859065),
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 32.h),
                    Text(
                      _splashVerse,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const Spacer(flex: 13),
                    SizedBox(
                      width: 42.r,
                      height: 42.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 5.r,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF859065),
                        ),
                        backgroundColor: const Color(0x80859065),
                      ),
                    ),
                    SizedBox(height: 44.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Browser presentation of the opening screen. The mobile composition above
/// remains untouched; on wider viewports the artwork and copy become two
/// balanced panels instead of a stretched phone canvas.
class _WebRamadanSplash extends StatelessWidget {
  const _WebRamadanSplash();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: _RamadanSplashScreenState._splashBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _RamadanSplashScreenState._backgroundImagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: _RamadanSplashScreenState._splashBackground,
            ),
          ),
          const ColoredBox(color: Color(0x99F8F8F4)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxWidth < 820 || constraints.maxHeight < 600;
                final horizontal = constraints.maxWidth >= 1280 ? 72.0 : 32.0;
                final content = compact
                    ? _WebSplashCompact(appText: appText)
                    : _WebSplashWide(appText: appText);
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontal,
                        vertical: 32,
                      ),
                      child: content,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WebSplashWide extends StatelessWidget {
  const _WebSplashWide({required this.appText});

  final AppText appText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 5, child: _WebSplashLogoPanel(appText: appText)),
        const SizedBox(width: 64),
        Expanded(flex: 6, child: _WebSplashCopyPanel(appText: appText)),
      ],
    );
  }
}

/// The visual anchor for a wide browser: deliberately just the logo, so the
/// reader's eye travels naturally to the copy and loading state beside it.
class _WebSplashLogoPanel extends StatelessWidget {
  const _WebSplashLogoPanel({required this.appText});

  final AppText appText;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFE0ECC0)],
          ),
          borderRadius: BorderRadius.circular(42),
          border: Border.all(color: const Color(0x99FFFFFF), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F52601F),
              blurRadius: 36,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            _RamadanSplashScreenState._logoImagePath,
            width: 210,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Text(
              appText.tuhfatulMuslim,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF65713F),
                fontSize: 34,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebSplashCopyPanel extends StatelessWidget {
  const _WebSplashCopyPanel({required this.appText});

  final AppText appText;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 510),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appText.tuhfatulMuslim,
              style: const TextStyle(
                color: Color(0xFF53622C),
                fontSize: 42,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              _RamadanSplashScreenState._splashVerse,
              style: TextStyle(
                color: Color(0xFF252C17),
                fontSize: 19,
                fontWeight: FontWeight.w600,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 42),
            const _WebSplashLoading(),
          ],
        ),
      ),
    );
  }
}

class _WebSplashLoading extends StatelessWidget {
  const _WebSplashLoading();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 3.5,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF718338)),
            backgroundColor: Color(0x66718338),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'Opening your spiritual companion',
          style: TextStyle(
            color: const Color(0xFF65713F).withValues(alpha: .9),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WebSplashCompact extends StatelessWidget {
  const _WebSplashCompact({required this.appText});

  final AppText appText;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _WebSplashBrand(appText: appText),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 280),
              child: Image.asset(
                _RamadanSplashScreenState._backgroundImagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebSplashBrand extends StatelessWidget {
  const _WebSplashBrand({required this.appText});

  final AppText appText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          _RamadanSplashScreenState._logoImagePath,
          width: 128,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Text(
            appText.tuhfatulMuslim,
            style: const TextStyle(
              color: Color(0xFF7D8765),
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          appText.tuhfatulMuslim,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF6B7844),
            fontSize: 27,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Text(
            _RamadanSplashScreenState._splashVerse,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF23291A),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 34),
        const SizedBox(
          width: 38,
          height: 38,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF859065)),
            backgroundColor: Color(0x80859065),
          ),
        ),
      ],
    );
  }
}
