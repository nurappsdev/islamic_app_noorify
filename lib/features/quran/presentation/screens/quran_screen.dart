import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/quranBack.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 8.h),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),
                        Image.asset(
                          'assets/images/bismillah.png',
                          height: 34.h,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          appText.categoryQuran,
                          style: TextStyle(
                            color: AppColor.primary,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          appText.quranIntroSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.inkColor(AppColor.authLogo),
                            fontSize: 13.sp,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 30.h),
                        const _QuranArtwork(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h),
                  child: SizedBox(
                    height: 54.h,
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushReplacementNamed(RouteNames.quranSurahs),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(29.r),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      label: Text(
                        appText.quranReadButton,
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
    );
  }
}

class _QuranArtwork extends StatelessWidget {
  const _QuranArtwork();

  Widget _cloud({required double size}) {
    return Icon(Icons.cloud_rounded, color: Colors.white, size: size);
  }

  Widget _sparkle({required double size}) {
    return Icon(Icons.auto_awesome, color: const Color(0xFFDCE7A6), size: size);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230.h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 6.w,
            top: 40.h,
            child: _cloud(size: 34.sp),
          ),
          Positioned(
            right: 4.w,
            top: 62.h,
            child: _cloud(size: 26.sp),
          ),
          Positioned(
            left: 30.w,
            top: 4.h,
            child: _sparkle(size: 16.sp),
          ),
          Positioned(
            right: 30.w,
            top: 20.h,
            child: _sparkle(size: 12.sp),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14.h,
            child: Center(
              child: Image.asset(
                'assets/images/Quran.png',
                height: 150.h,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
