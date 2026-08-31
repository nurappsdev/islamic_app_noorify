import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

/// Intro / "get started" screen for the Hadith section.
///
/// Reached from the Hadith card on the Home screen. The primary action
/// pushes the Hadith library screen.
class HadithIntroScreen extends StatelessWidget {
  const HadithIntroScreen({super.key});

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
              Color(0xFFF1F5E4),
              Color(0xFFD8E5BC),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
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
                  padding: EdgeInsets.symmetric(horizontal: 28.w),
                  child: Column(
                    children: [
                      SizedBox(height: 70.h),
                      Text(
                        appText.hadithIntroTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF7D8765),
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        appText.hadithIntroSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF4C5346),
                          fontSize: 13.sp,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 40.h),
                      Icon(
                        Icons.menu_book_rounded,
                        size: 190.sp,
                        color: Colors.white.withValues(alpha: .55),
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
                    ).pushNamed(RouteNames.hadithLibrary),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                    ),
                    child: Text(
                      appText.hadithIntroStartButton,
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
      ),
    );
  }
}
