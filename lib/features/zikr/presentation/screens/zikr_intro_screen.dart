import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

/// Intro / "get started" screen for the Zikr section.
///
/// Reached from the Zikr tile on the Home screen. The primary action pushes the
/// Zikr dashboard.
class ZikrIntroScreen extends StatelessWidget {
  const ZikrIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDFEFB),
              Color(0xFFF3F6E8),
              Color(0xFFDCE6C4),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _Decor()),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 18.w),
                      child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFDFDE68),
                          foregroundColor: const Color(0xFF303629),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 30.w),
                      child: Column(
                        children: [
                          SizedBox(height: 210.h),
                          Text(
                            appText.zikrIntroTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF7D8765),
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            appText.zikrIntroSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF4C5346),
                              fontSize: 13.sp,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(40.w, 12.h, 40.w, 26.h),
                    child: SizedBox(
                      height: 52.h,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(RouteNames.zikrDashboard),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.r),
                          ),
                        ),
                        child: Text(
                          appText.zikrIntroStartButton,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faint crescent + star at the top and a mosque silhouette along the bottom.
class _Decor extends StatelessWidget {
  const _Decor();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 70.h,
            left: 40.w,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.rotate(
                  angle: 0.4,
                  child: Icon(
                    Icons.nightlight_round,
                    size: 68.sp,
                    color: const Color(0xFFC9B26B).withValues(alpha: .35),
                  ),
                ),
                SizedBox(width: 4.w),
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Icon(
                    Icons.star_rounded,
                    size: 26.sp,
                    color: const Color(0xFFC9B26B).withValues(alpha: .35),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Icon(
              Icons.mosque_rounded,
              size: 300.sp,
              color: Colors.white.withValues(alpha: .45),
            ),
          ),
        ],
      ),
    );
  }
}
