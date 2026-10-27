import 'dart:async';

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
