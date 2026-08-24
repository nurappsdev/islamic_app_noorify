import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_bottom_nav.dart';

class QuizCategoriesScreen extends StatelessWidget {
  const QuizCategoriesScreen({super.key});

  static List<_QuizCategory> _categories(AppText appText) => [
    _QuizCategory(
      title: appText.exploreQuranicSciences,
      quizzes: '120 ${appText.quizzesCountLabel}',
      score: '950',
    ),
    _QuizCategory(
      title: appText.seerahAndHistory,
      quizzes: '85 ${appText.quizzesCountLabel}',
      score: '810',
    ),
    _QuizCategory(
      title: appText.islamicManners,
      quizzes: '60 ${appText.quizzesCountLabel}',
      score: '720',
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
                const _QuizHero(),
                Padding(
                  padding: EdgeInsets.fromLTRB(23.w, 24.h, 23.w, 0),
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
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Column(
                    children: [
                      for (final category in categories) ...[
                        _CategoryCard(category: category),
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

class _QuizHero extends StatelessWidget {
  const _QuizHero();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      height: 250.h,
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 26.w, 30.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE3ECC1),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(38.r),
          bottomRight: Radius.circular(38.r),
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFDFDE68),
                foregroundColor: const Color(0xFF303629),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            ),
          ),
          Positioned(
            left: 22.w,
            bottom: 6.h,
            child: SizedBox(
              width: 168.w,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appText.completeTodaysChallenge,
                    style: TextStyle(
                      color: AppColor.primary,
                      fontSize: 22.sp,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  FilledButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.quizQuestion),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 11.h,
                      ),
                    ),
                    child: Text(
                      appText.letsGetStart,
                      style: TextStyle(fontSize: 11.sp),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(right: 0, bottom: 0, child: _QuizArtwork(size: 130.w)),
        ],
      ),
    );
  }
}

class _QuizArtwork extends StatelessWidget {
  const _QuizArtwork({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      children: [
        Positioned(
          right: 12,
          top: 16,
          child: Transform.rotate(
            angle: -.24,
            child: Container(
              width: size * .58,
              height: size * .65,
              decoration: BoxDecoration(
                color: const Color(0xFF6DD575),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: Text(
                  'N',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * .18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 35,
          child: Container(
            width: size * .42,
            height: size * .42,
            decoration: const BoxDecoration(
              color: Color(0xFF269C54),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        Positioned(
          left: 2,
          bottom: 11,
          child: Transform.rotate(
            angle: .5,
            child: Icon(
              Icons.search_rounded,
              color: const Color(0xFF3E5C3C),
              size: size * .48,
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 0,
          child: Icon(
            Icons.auto_awesome_rounded,
            color: const Color(0xFFC5B9D8),
            size: size * .53,
          ),
        ),
      ],
    ),
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});
  final _QuizCategory category;

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

class _QuizCategory {
  const _QuizCategory({
    required this.title,
    required this.quizzes,
    required this.score,
  });
  final String title;
  final String quizzes;
  final String score;
}
