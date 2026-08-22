import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/features/planner/presentation/cubit/planner_cubit.dart';
import 'package:islami_app_noorify/features/planner/presentation/models/planner_plan.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_bottom_nav.dart';

/// The user's active plans, reached from index 2 of the Quiz navigation bar.
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlannerCubit(),
      child: const _PlannerView(),
    );
  }
}

class _PlannerView extends StatelessWidget {
  const _PlannerView();

  static const _plans = [
    PlannerPlan(title: 'Plan 1', quizCount: 10, detailQuizCount: 4),
    PlannerPlan(title: 'Plan 2', quizCount: 3, detailQuizCount: 3),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerCubit>().state;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _PlanTabs(
                  showCompletedPlans: state.showCompletedPlans,
                  onTabChanged: context.read<PlannerCubit>().showCompletedPlans,
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: state.showCompletedPlans
                      ? Transform.translate(
                          offset: Offset(0, -34.h),
                          child: const _EmptyCompletedPlans(),
                        )
                      : Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Column(
                            children: [
                              for (final plan in _plans) ...[
                                _PlanCard(
                                  plan: plan,
                                  onGetStarted: () =>
                                      Navigator.of(context).pushNamed(
                                        RouteNames.plannerDetails,
                                        arguments: plan,
                                      ),
                                ),
                                SizedBox(height: 12.h),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: QuizBottomNav(selectedIndex: 2),
            ),
            if (!state.showCompletedPlans)
              Positioned(
                right: 58.w,
                bottom: 104.h,
                child: FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(RouteNames.createPlan),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA1AD59),
                    foregroundColor: Colors.white,
                    minimumSize: Size(127.w, 48.h),
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  icon: Icon(Icons.edit_outlined, size: 20.sp),
                  label: Text(
                    'Create Plan',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
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

class _PlanTabs extends StatelessWidget {
  const _PlanTabs({
    required this.showCompletedPlans,
    required this.onTabChanged,
  });

  final bool showCompletedPlans;
  final ValueChanged<bool> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(72.w, 7.h, 72.w, 0),
      child: SizedBox(
        height: 36.h,
        child: Row(
          children: [
            _PlanTab(
              label: 'My Plan',
              selected: !showCompletedPlans,
              onPressed: () => onTabChanged(false),
            ),
            Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 1.h,
                      color: const Color(0xFFDDE8C1),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: _PlanTab(
                      label: 'Complete Plan',
                      selected: showCompletedPlans,
                      onPressed: () => onTabChanged(true),
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

class _PlanTab extends StatelessWidget {
  const _PlanTab({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: 112.w,
          height: 36.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFDDE8BA) : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _EmptyCompletedPlans extends StatelessWidget {
  const _EmptyCompletedPlans();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100.w,
            height: 91.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.sticky_note_2_rounded,
                  color: const Color(0xFFDDE8BA),
                  size: 86.sp,
                ),
                Positioned(
                  top: 27.h,
                  child: Text(
                    '?',
                    style: TextStyle(
                      color: const Color(0xFF84945F),
                      fontSize: 31.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  top: 18.h,
                  left: 6.w,
                  child: Icon(
                    Icons.wb_sunny_outlined,
                    color: const Color(0xFF84945F),
                    size: 25.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 13.h),
          Text(
            'You cannot complete any\nplan yet !',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF989898),
              fontSize: 13.sp,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onGetStarted});

  final PlannerPlan plan;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDE8C1)),
        borderRadius: BorderRadius.circular(21.r),
      ),
      child: Row(
        children: [
          const _PlanArtwork(),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: TextStyle(
                    color: const Color(0xFF332B57),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 7.h),
                Text(
                  '${plan.quizCount} Quiz',
                  style: TextStyle(
                    color: const Color(0xFF929BB6),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onGetStarted,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDDE8BA),
              foregroundColor: const Color(0xFF303629),
              minimumSize: Size(89.w, 36.h),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text('Get Start', style: TextStyle(fontSize: 12.sp)),
          ),
          SizedBox(width: 8.w),
          Icon(Icons.more_vert_rounded, color: Colors.black, size: 20.sp),
        ],
      ),
    );
  }
}

class _PlanArtwork extends StatelessWidget {
  const _PlanArtwork();

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
