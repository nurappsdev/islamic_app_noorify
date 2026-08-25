import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/planner/presentation/models/planner_plan.dart';

/// Quiz list shown after selecting Get Start on a plan card.
class PlannerDetailScreen extends StatelessWidget {
  const PlannerDetailScreen({super.key, required this.plan});

  final PlannerPlan plan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _PlannerHeader(
              title: plan.title,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 18.h),
                itemCount: plan.detailQuizCount,
                separatorBuilder: (_, _) => SizedBox(height: 7.h),
                itemBuilder: (context, index) =>
                    _PlanQuizCard(index: index + 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannerHeader extends StatelessWidget {
  const _PlannerHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFDDE8C1))),
      ),
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
                minimumSize: Size(33.w, 33.w),
                padding: EdgeInsets.zero,
              ),
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 15.sp),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF84945F),
              fontSize: 18.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanQuizCard extends StatelessWidget {
  const _PlanQuizCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDE8C1)),
        borderRadius: BorderRadius.circular(21.r),
      ),
      child: Row(
        children: [
          const _QuizArtwork(),
          SizedBox(width: 10.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppText.of(context).categoryQuiz} $index '
                '( ${AppText.of(context).quranicScience} )',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400),
              ),
              SizedBox(height: 7.h),
              Text(
                AppText.of(context).questionsCountLabel,
                style: TextStyle(
                  color: const Color(0xFFA1AD59),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizArtwork extends StatelessWidget {
  const _QuizArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 47.w,
      height: 47.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDDE8C1)),
      ),
      child: Icon(
        Icons.image_outlined,
        color: const Color(0xFF8B9865),
        size: 23.sp,
      ),
    );
  }
}
