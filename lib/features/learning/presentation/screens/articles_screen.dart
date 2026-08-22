import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 24.h),
              children: [
                _ArticleHeader(
                  title: 'All articles',
                  onBack: () => Navigator.maybePop(context),
                ),
                SizedBox(height: 21.h),
                _ArticlePreview(
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(RouteNames.learningArticleDetails),
                ),
                SizedBox(height: 7.h),
                _ArticlePreview(
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(RouteNames.learningArticleDetails),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: Container(
                  height: 126.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        const Color(0xFFE4EDBF),
                      ],
                    ),
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

class _ArticleHeader extends StatelessWidget {
  const _ArticleHeader({required this.title, required this.onBack});
  final String title;
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
          title,
          style: TextStyle(color: AppColor.primary, fontSize: 18.sp),
        ),
      ],
    ),
  );
}

class _ArticlePreview extends StatelessWidget {
  const _ArticlePreview({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(11.r),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11.r),
      child: Container(
        padding: EdgeInsets.fromLTRB(8.w, 10.h, 8.w, 10.h),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDDE8B5)),
          borderRadius: BorderRadius.circular(11.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The Power of Sabr in Islam',
              style: TextStyle(color: AppColor.primary, fontSize: 14.sp),
            ),
            SizedBox(height: 7.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDE8B5)),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Text(
                'Islamic Guidance',
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
            SizedBox(height: 7.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Image.asset(
                'assets/islamicImg.png',
                width: double.infinity,
                height: 170.h,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Learn how patience helps Muslims remain steadfast\nthrough difficulties and strengthens their trust in Allah.',
              style: TextStyle(fontSize: 11.sp, height: 1.4),
            ),
            SizedBox(height: 8.h),
            Text(
              'See More . . .',
              style: TextStyle(
                color: AppColor.primary,
                decoration: TextDecoration.underline,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 9.h),
            Text(
              'Post Date: August 17, 2026   10:00 AM',
              style: TextStyle(color: AppColor.primary, fontSize: 11.sp),
            ),
          ],
        ),
      ),
    ),
  );
}
