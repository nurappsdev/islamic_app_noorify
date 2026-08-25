import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/learning/presentation/bloc/learning_test_bloc.dart';

class LearningTestScreen extends StatelessWidget {
  const LearningTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LearningTestBloc(),
      child: const _LearningTestView(),
    );
  }
}

class _LearningTestView extends StatelessWidget {
  const _LearningTestView();

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<LearningTestBloc>().state.selectedAnswers;
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(13.w, 14.h, 13.w, 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TestHeader(onBack: () => Navigator.maybePop(context)),
              SizedBox(height: 20.h),
              const Center(child: _TestTimer()),
              SizedBox(height: 17.h),
              Text(
                appText.questionProgressLabel,
                style: TextStyle(fontSize: 13.sp),
              ),
              SizedBox(height: 14.h),
              const _TestProgress(),
              SizedBox(height: 17.h),
              Text(
                appText.questionsTitlePlaceholder,
                style: TextStyle(fontSize: 13.sp),
              ),
              SizedBox(height: 10.h),
              for (var index = 0; index < 5; index++) ...[
                _TestAnswer(
                  letter: String.fromCharCode(97 + index),
                  label: '${appText.answerLabelPrefix} ${index + 1}',
                  selected: selected.contains(index),
                  onTap: () =>
                      context.read<LearningTestBloc>().add(ToggleAnswer(index)),
                ),
                SizedBox(height: 6.h),
              ],
              const Spacer(),
              Center(
                child: Text(
                  appText.quizTimingProgress,
                  style: TextStyle(
                    color: const Color(0xFF5D876A),
                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              const _TestTimingProgress(),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.fromHeight(42.h),
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: Color(0xFFD6D6D6)),
                      ),
                      child: Text(
                        appText.previous,
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () => Navigator.of(context).pushReplacementNamed(
                              RouteNames.learningTestResult,
                            ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF899868),
                        disabledBackgroundColor: const Color(0xFFE2E2E2),
                        minimumSize: Size.fromHeight(42.h),
                      ),
                      child: Text(
                        appText.next,
                        style: TextStyle(fontSize: 13.sp),
                      ),
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

class _TestHeader extends StatelessWidget {
  const _TestHeader({required this.onBack});
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
          AppText.of(context).categoryQuiz,
          style: TextStyle(color: AppColor.primary, fontSize: 18.sp),
        ),
      ],
    ),
  );
}

class _TestTimer extends StatelessWidget {
  const _TestTimer();
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 13.h),
    decoration: BoxDecoration(
      color: AppColor.primary,
      borderRadius: BorderRadius.circular(26.r),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time_rounded, color: Colors.white, size: 21.sp),
        SizedBox(width: 9.w),
        Text(
          AppText.of(context).timesRemainingLabel,
          style: TextStyle(color: Colors.white, fontSize: 13.sp),
        ),
      ],
    ),
  );
}

class _TestProgress extends StatelessWidget {
  const _TestProgress();
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.centerLeft,
    children: [
      Container(
        height: 8.h,
        decoration: BoxDecoration(
          color: const Color(0xFFE9E9E9),
          borderRadius: BorderRadius.circular(9.r),
        ),
      ),
      FractionallySizedBox(
        widthFactor: .6,
        child: Container(
          height: 8.h,
          decoration: BoxDecoration(
            color: AppColor.primary,
            borderRadius: BorderRadius.circular(9.r),
          ),
        ),
      ),
      Align(
        alignment: const Alignment(-.03, 0),
        child: Container(
          width: 20.r,
          height: 20.r,
          decoration: const BoxDecoration(
            color: AppColor.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ],
  );
}

class _TestAnswer extends StatelessWidget {
  const _TestAnswer({
    required this.letter,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String letter, label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF2F6E7),
    borderRadius: BorderRadius.circular(15.r),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        height: 43.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Row(
          children: [
            Container(
              width: 27.r,
              height: 27.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDDE8B5)),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  color: const Color(0xFF596254),
                  fontSize: 13.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF899580),
                  fontSize: 12.sp,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 23.r,
                height: 23.r,
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _TestTimingProgress extends StatelessWidget {
  const _TestTimingProgress();
  @override
  Widget build(BuildContext context) => Container(
    height: 52.h,
    decoration: BoxDecoration(
      color: const Color(0xFFDDE8B5),
      borderRadius: BorderRadius.circular(28.r),
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 55.r,
        height: 55.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFDDE8B5),
          border: Border.all(color: Colors.white.withValues(alpha: .7)),
        ),
        child: Text(
          '23 %',
          style: TextStyle(color: const Color(0xFF5D876A), fontSize: 12.sp),
        ),
      ),
    ),
  );
}
