import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';

class QuizQuestionScreen extends StatefulWidget {
  const QuizQuestionScreen({super.key});

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  static const _answers = ['Answer 1', 'Answer 2', 'Answer 3', 'Answer 4'];
  int? _selectedAnswer;

  @override
  Widget build(BuildContext context) {
    final canContinue = _selectedAnswer != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuizAppBar(onBack: () => Navigator.maybePop(context)),
              SizedBox(height: 19.h),
              Center(child: const _TimerPill()),
              SizedBox(height: 18.h),
              Text('Question 8 of 12', style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 14.h),
              const _QuestionProgress(),
              SizedBox(height: 17.h),
              Text('Questions title', style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 10.h),
              for (var index = 0; index < _answers.length; index++) ...[
                _AnswerTile(
                  label: String.fromCharCode(97 + index),
                  answer: _answers[index],
                  selected: _selectedAnswer == index,
                  onTap: () => setState(() => _selectedAnswer = index),
                ),
                SizedBox(height: 5.h),
              ],
              const Spacer(),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 22.w,
                    vertical: 15.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE8B5),
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                  child: Text(
                    '50/50  CHANCE',
                    style: TextStyle(
                      color: const Color(0xFF5F8671),
                      fontSize: 18.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 21.h),
              Center(
                child: Text(
                  'This quiz timing progress',
                  style: TextStyle(
                    color: const Color(0xFF5D876A),
                    fontSize: 13.sp,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              const _TimingProgress(),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.fromHeight(45.h),
                        shape: StadiumBorder(),
                        side: BorderSide(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Text(
                        'Previous',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: canContinue
                          ? () => Navigator.of(
                              context,
                            ).pushReplacementNamed(RouteNames.quizComplete)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF879765),
                        disabledBackgroundColor: const Color(0xFFE2E2E2),
                        minimumSize: Size.fromHeight(45.h),
                      ),
                      child: Text('Next', style: TextStyle(fontSize: 13.sp)),
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

class _QuizAppBar extends StatelessWidget {
  const _QuizAppBar({required this.onBack});
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
          'Quiz',
          style: TextStyle(color: AppColor.primary, fontSize: 18.sp),
        ),
      ],
    ),
  );
}

class _TimerPill extends StatelessWidget {
  const _TimerPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 13.h),
    decoration: BoxDecoration(
      color: AppColor.primary,
      borderRadius: BorderRadius.circular(28.r),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time_rounded, color: Colors.white, size: 22.sp),
        SizedBox(width: 10.w),
        Text(
          'Times remaining : 07 : 03 sec',
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
        ),
      ],
    ),
  );
}

class _QuestionProgress extends StatelessWidget {
  const _QuestionProgress();

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.centerLeft,
    children: [
      Container(
        height: 8.h,
        decoration: BoxDecoration(
          color: const Color(0xFFE9E9E9),
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
      FractionallySizedBox(
        widthFactor: 8 / 12,
        child: Container(
          height: 8.h,
          decoration: BoxDecoration(
            color: AppColor.primary,
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
      ),
      Align(
        alignment: const Alignment(-.02, 0),
        child: Container(
          width: 22.r,
          height: 22.r,
          decoration: const BoxDecoration(
            color: AppColor.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ],
  );
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.label,
    required this.answer,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String answer;
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
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Row(
          children: [
            Container(
              height: 29.r,
              width: 29.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDE8B5)),
                shape: BoxShape.circle,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF596254),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF899580),
                ),
              ),
            ),
            if (selected)
              Container(
                height: 24.r,
                width: 24.r,
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const SizedBox(),
              ),
          ],
        ),
      ),
    ),
  );
}

class _TimingProgress extends StatelessWidget {
  const _TimingProgress();

  @override
  Widget build(BuildContext context) => Container(
    height: 55.h,
    decoration: BoxDecoration(
      color: const Color(0xFFDDE8B5),
      borderRadius: BorderRadius.circular(30.r),
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 58.r,
        height: 58.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFDDE8B5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .7)),
        ),
        child: Text(
          '23 %',
          style: TextStyle(color: const Color(0xFF5D876A), fontSize: 13.sp),
        ),
      ),
    ),
  );
}
