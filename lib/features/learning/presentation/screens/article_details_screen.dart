import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

class ArticleDetailsScreen extends StatelessWidget {
  const ArticleDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 91.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailsHeader(onBack: () => Navigator.maybePop(context)),
                  SizedBox(height: 22.h),
                  Text(
                    appText.articleTitleSabr,
                    style: TextStyle(color: AppColor.primary, fontSize: 15.sp),
                  ),
                  SizedBox(height: 9.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 11.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDDE8B5)),
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    child: Text(
                      appText.articleTagIslamicGuidance,
                      style: TextStyle(fontSize: 11.sp),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    appText.postDatePlaceholder,
                    style: TextStyle(color: AppColor.primary, fontSize: 12.sp),
                  ),
                  SizedBox(height: 9.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Image.asset(
                      'assets/islamicImg.png',
                      width: double.infinity,
                      height: 170.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    appText.articleFullTextSabr,
                    style: TextStyle(fontSize: 12.sp, height: 1.45),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(RouteNames.learningTest),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    minimumSize: Size(double.infinity, 55.h),
                  ),
                  child: Text(
                    appText.testLearning,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38.h,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFDFDE68),
              foregroundColor: const Color(0xFF303629),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        Text(
          AppText.of(context).articlesDetails,
          style: TextStyle(color: AppColor.primary, fontSize: 18.sp),
        ),
      ],
    ),
  );
}
