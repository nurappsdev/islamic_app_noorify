import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

class QuizListScreen extends StatelessWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 0),
          child: Column(
            children: [
              _QuizListHeader(onBack: () => Navigator.maybePop(context)),
              SizedBox(height: 12.h),
              Expanded(
                child: ListView.separated(
                  itemCount: 4,
                  separatorBuilder: (_, _) => SizedBox(height: 7.h),
                  itemBuilder: (context, index) => _QuizListTile(
                    quizNumber: index + 1,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.quizQuestion),
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

class _QuizListHeader extends StatelessWidget {
  const _QuizListHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 35.h,
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
          AppText.of(context).quranicScience,
          style: TextStyle(color: AppColor.primary, fontSize: 18.sp),
        ),
      ],
    ),
  );
}

class _QuizListTile extends StatelessWidget {
  const _QuizListTile({required this.quizNumber, required this.onTap});
  final int quizNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          height: 75.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDE8B5)),
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Row(
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDDE8B5)),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: AppColor.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${appText.categoryQuiz} $quizNumber',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 7.h),
                  Text(
                    appText.questionsCountLabel,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColor.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
