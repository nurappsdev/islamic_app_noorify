import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_bottom_nav.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 89.h),
              children: [
                _LearningHeader(onBack: () => Navigator.maybePop(context)),
                SizedBox(height: 22.h),
                const _SectionTitle('Explore'),
                SizedBox(height: 15.h),
                SizedBox(
                  height: 129.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: const [
                      _ExploreCard('Quranic Sciences', '7 Articles'),
                      _ExploreCard('Daily life', '5 Articles'),
                      _ExploreCard('Islamic history', '8 Articles'),
                    ],
                  ),
                ),
                SizedBox(height: 21.h),
                _SectionTitle(
                  'Recent articles',
                  onSeeAll: () => Navigator.of(
                    context,
                  ).pushNamed(RouteNames.learningArticles),
                ),
                SizedBox(height: 17.h),
                const _ArticleCard(),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: QuizBottomNav(selectedIndex: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningHeader extends StatelessWidget {
  const _LearningHeader({required this.onBack});
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
          'Learning',
          style: TextStyle(color: AppColor.primary, fontSize: 18.sp),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
      ),
      TextButton(
        onPressed: onSeeAll ?? () {},
        child: Text(
          'See All',
          style: TextStyle(color: Colors.black, fontSize: 12.sp),
        ),
      ),
    ],
  );
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard(this.title, this.articleCount);
  final String title;
  final String articleCount;

  @override
  Widget build(BuildContext context) => Container(
    width: 147.w,
    margin: EdgeInsets.only(right: 8.w),
    padding: EdgeInsets.fromLTRB(16.w, 20.h, 10.w, 14.h),
    decoration: BoxDecoration(
      color: const Color(0xFFDFE9B9),
      borderRadius: BorderRadius.circular(18.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 13.sp)),
        SizedBox(height: 15.h),
        Text(
          articleCount,
          style: TextStyle(color: const Color(0xFF718060), fontSize: 12.sp),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () {},
          iconAlignment: IconAlignment.end,
          icon: Icon(Icons.north_east_rounded, size: 16.sp),
          label: const Text('Explore'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF637354),
            side: const BorderSide(color: AppColor.primary),
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            minimumSize: Size(0, 34.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(8.w, 10.h, 8.w, 9.h),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F6E7),
      border: Border.all(color: const Color(0xFFDDE8B5)),
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          child: Text(
            'The Power of Sabr in Islam',
            style: TextStyle(color: AppColor.primary, fontSize: 14.sp),
          ),
        ),
        SizedBox(height: 7.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDDE8B5)),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Text('Islamic Guidance', style: TextStyle(fontSize: 11.sp)),
        ),
        SizedBox(height: 7.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(11.r),
          child: Image.asset(
            'assets/islamicImg.png',
            width: double.infinity,
            height: 160.h,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: 7.h),
        Text(
          'Learn how patience helps Muslims remain steadfast\nthrough difficulties and strengthens their trust in Allah.',
          style: TextStyle(fontSize: 11.sp, height: 1.45),
        ),
        SizedBox(height: 8.h),
        Text(
          'See More...',
          style: TextStyle(
            color: AppColor.primary,
            decoration: TextDecoration.underline,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Post Date: August 17, 2026   10:00 AM',
          style: TextStyle(color: const Color(0xFFB0C573), fontSize: 11.sp),
        ),
      ],
    ),
  );
}
