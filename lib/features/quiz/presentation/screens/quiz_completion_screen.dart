import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_bottom_nav.dart';

class QuizCompletionScreen extends StatelessWidget {
  const QuizCompletionScreen({super.key});

  static List<_CompletedCategory> _categories(AppText appText) => [
    _CompletedCategory(
      appText.exploreQuranicSciences,
      '120 ${appText.quizzesCountLabel}',
      '950',
    ),
    _CompletedCategory(
      appText.seerahAndHistory,
      '85 ${appText.quizzesCountLabel}',
      '810',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final categories = _categories(appText);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(bottom: 90.h),
              children: [
                _CompletionHero(onBack: () => Navigator.maybePop(context)),
                Padding(
                  padding: EdgeInsets.fromLTRB(22.w, 23.h, 22.w, 14.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        appText.categories,
                        style: TextStyle(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(RouteNames.quizList),
                        child: Text(
                          appText.seeAll,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 13.w),
                  child: Column(
                    children: [
                      for (final category in categories) ...[
                        _CompletedCategoryCard(category: category),
                        SizedBox(height: 9.h),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: QuizBottomNav(selectedIndex: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionHero extends StatelessWidget {
  const _CompletionHero({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      height: 246.h,
      padding: EdgeInsets.fromLTRB(19.w, 16.h, 24.w, 28.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE4ECC5),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(37.r),
          bottomRight: Radius.circular(37.r),
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: onBack,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFDFDE68),
                foregroundColor: const Color(0xFF303629),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            ),
          ),
          Positioned(
            left: 20.w,
            bottom: 23.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appText.youCompletedTodaysChallenge,
                  style: TextStyle(
                    color: AppColor.primary,
                    fontSize: 22.sp,
                    height: 1.28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 28.h),
                Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFF31555D),
                      size: 31,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      '${appText.todaysPointsLabel} : 0.5',
                      style: TextStyle(
                        color: AppColor.primary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(right: 0, bottom: 6.h, child: const _SuccessMark()),
        ],
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 143.w,
    height: 132.w,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -.18,
          child: Container(
            width: 106.w,
            height: 106.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F4),
              borderRadius: BorderRadius.circular(35.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .12),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
        ),
        Icon(
          Icons.check_rounded,
          color: const Color(0xFF82D020),
          size: 87.sp,
          shadows: [
            Shadow(
              color: const Color(0xFF4B8A11).withValues(alpha: .6),
              offset: const Offset(2, 4),
              blurRadius: 2,
            ),
          ],
        ),
      ],
    ),
  );
}

class _CompletedCategoryCard extends StatelessWidget {
  const _CompletedCategoryCard({required this.category});
  final _CompletedCategory category;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(19.w),
    decoration: BoxDecoration(
      color: const Color(0xFFDFE9B9),
      borderRadius: BorderRadius.circular(18.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 27.r,
              height: 27.r,
              decoration: BoxDecoration(
                border: Border.all(color: AppColor.primary),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: 16.sp,
                color: AppColor.primary,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              iconAlignment: IconAlignment.end,
              icon: Icon(Icons.north_east_rounded, size: 17.sp),
              label: Text(AppText.of(context).explore),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4D5542),
                side: const BorderSide(color: AppColor.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11.r),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          category.title,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 14.h),
        Text(
          category.quizzes,
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFF56614F)),
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Text(
              AppText.of(context).highScore,
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF697269)),
            ),
            SizedBox(width: 10.w),
            Text(
              category.score,
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF89958B)),
            ),
            Icon(
              Icons.workspace_premium_outlined,
              size: 14.sp,
              color: const Color(0xFF89958B),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CompletedCategory {
  const _CompletedCategory(this.title, this.quizzes, this.score);
  final String title;
  final String quizzes;
  final String score;
}
