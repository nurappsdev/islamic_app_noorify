import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

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
          image: DecorationImage(
            image: AssetImage('assets/zikr/zikrPlashImg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
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
                          backgroundColor: context.surfaceColor(
                            Color(0xFFDFDE68),
                          ),
                          foregroundColor: context.inkColor(Color(0xFF303629)),
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
                              color: context.inkColor(Color(0xFF7D8765)),
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            appText.zikrIntroSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.inkColor(Color(0xFF4C5346)),
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
