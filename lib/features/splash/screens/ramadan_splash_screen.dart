import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/utils/app_text.dart';
import '../utils/post_splash_route.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';

class RamadanSplashScreen extends StatefulWidget {
  const RamadanSplashScreen({super.key});

  @override
  State<RamadanSplashScreen> createState() => _RamadanSplashScreenState();
}

class _RamadanSplashScreenState extends State<RamadanSplashScreen> {
  static const _splashDuration = Duration(milliseconds: 1800);
  static const _backgroundImagePath = 'assets/splasImg.png';
  static const _logoImagePath = 'assets/noorifyLogo.png';

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

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _backgroundImagePath,
              key: const Key('opening_splash_image'),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return ColoredBox(
                  color: context.surfaceColor(Color(0xFFF8F8F4)),
                );
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
                          'Noorify',
                          style: TextStyle(
                            color: context.inkColor(Color(0xFF7D8765)),
                            fontSize: 30.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      appText.noorify,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.inkColor(Colors.black),
                        fontSize: 15.sp,
                        height: 1.2,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    SizedBox(height: 48.h),
                    Text(
                      appText.splashTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.inkColor(Colors.black),
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    SizedBox(height: 28.h),
                    Text(
                      '"${appText.splashQuote}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.inkColor(Colors.black),
                        fontSize: 16.sp,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    const Spacer(flex: 13),
                    SizedBox(
                      width: 42.r,
                      height: 42.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 5.r,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF9BA680),
                        ),
                        backgroundColor: const Color(0x669BA680),
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
