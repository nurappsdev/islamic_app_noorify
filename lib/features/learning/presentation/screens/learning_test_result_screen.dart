import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';

class LearningTestResultScreen extends StatelessWidget {
  const LearningTestResultScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(12.w, 15.h, 12.w, 16.h),
        child: Column(
          children: [
            _ResultHeader(onBack: () => Navigator.maybePop(context)),
            SizedBox(height: 27.h),
            const _ScoreRing(),
            SizedBox(height: 12.h),
            Text(
              'Quiz score',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.h),
            Text('Sabr', style: TextStyle(fontSize: 11.sp)),
            SizedBox(height: 14.h),
            Text(
              'Excellent Work! Your Answering Accuracy Is Very Good.\nKeep Up The Great Effort, And Continue Challenging\nYourself To Improve Even Further.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.sp, height: 1.35),
            ),
            SizedBox(height: 27.h),
            Row(
              children: const [
                Expanded(
                  child: _Metric(
                    icon: Icons.access_time_rounded,
                    label: 'Time Spent',
                    value: '6 : 17 min',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _Metric(
                    icon: Icons.show_chart_rounded,
                    label: 'Accuracy',
                    value: 'High',
                  ),
                ),
              ],
            ),
            SizedBox(height: 23.h),
            const _AnswerResult(correct: true, count: '13'),
            SizedBox(height: 10.h),
            const _AnswerResult(correct: false, count: '7'),
            SizedBox(height: 22.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Whats Next', style: TextStyle(fontSize: 15.sp)),
            ),
            SizedBox(height: 8.h),
            Text(
              'Would you like to move on to the next quiz? Click Next to\ncontinue, or choose Retry to retake the quiz and\nstrengthen your understanding.',
              style: TextStyle(fontSize: 9.sp, height: 1.4),
            ),
            SizedBox(height: 14.h),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.primary,
                minimumSize: Size(double.infinity, 40.h),
              ),
              child: Text(
                'Continue To Next',
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
            SizedBox(height: 7.h),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.primary,
                side: const BorderSide(color: AppColor.primary),
                minimumSize: Size(double.infinity, 40.h),
              ),
              child: Text('Retry Quiz', style: TextStyle(fontSize: 11.sp)),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    ),
  );
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.onBack});
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
              minimumSize: Size(35.r, 35.r),
              padding: EdgeInsets.zero,
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

class _ScoreRing extends StatelessWidget {
  const _ScoreRing();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 154.r,
    height: 154.r,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 154.r,
          height: 154.r,
          child: CircularProgressIndicator(
            value: .67,
            strokeWidth: 12.r,
            backgroundColor: const Color(0xFFFF7C7E),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF22CC53)),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '67%',
              style: TextStyle(color: const Color(0xFF22CC53), fontSize: 26.sp),
            ),
            Text('Overall score', style: TextStyle(fontSize: 11.sp)),
          ],
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    height: 105.h,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE5E5E5)),
      borderRadius: BorderRadius.circular(13.r),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 21.sp, color: AppColor.primary),
        SizedBox(height: 7.h),
        Text(label, style: TextStyle(fontSize: 11.sp)),
        SizedBox(height: 7.h),
        Text(
          value,
          style: TextStyle(fontSize: 12.sp, color: AppColor.primary),
        ),
      ],
    ),
  );
}

class _AnswerResult extends StatelessWidget {
  const _AnswerResult({required this.correct, required this.count});
  final bool correct;
  final String count;
  @override
  Widget build(BuildContext context) {
    final color = correct ? const Color(0xFF20C664) : const Color(0xFFC90009);
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F0),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13.r,
                backgroundColor: color,
                child: Icon(
                  correct ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
              const Spacer(),
              Text(
                count,
                style: TextStyle(color: color, fontSize: 14.sp),
              ),
            ],
          ),
          SizedBox(height: 13.h),
          Text(
            correct ? 'Correct answers' : 'Incorrect answers',
            style: TextStyle(fontSize: 12.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            correct
                ? 'You are trying your best your correct answer is 13 out of 20. Lets try to read learn more.'
                : 'You are trying your best your correct answer is 7 out of 20. View incorrect answer and learn about it.',
            style: TextStyle(fontSize: 9.sp, height: 1.35),
          ),
          SizedBox(height: 13.h),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              minimumSize: Size(double.infinity, 39.h),
            ),
            child: Text(
              correct ? 'View Correct Answer' : 'View Incorrect Answer',
              style: TextStyle(fontSize: 10.sp),
            ),
          ),
        ],
      ),
    );
  }
}
