import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

class LearningTestResultScreen extends StatelessWidget {
  const LearningTestResultScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
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
                appText.quizScore,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),
              Text(appText.testSubjectSabr, style: TextStyle(fontSize: 11.sp)),
              SizedBox(height: 14.h),
              Text(
                appText.excellentWorkMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.sp, height: 1.35),
              ),
              SizedBox(height: 27.h),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      icon: Icons.access_time_rounded,
                      label: appText.timeSpent,
                      value: '6 : 17 min',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Metric(
                      icon: Icons.show_chart_rounded,
                      label: appText.accuracy,
                      value: appText.accuracyHigh,
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
                child: Text(
                  appText.whatsNext,
                  style: TextStyle(fontSize: 15.sp),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                appText.whatsNextMessage,
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
                  appText.continueToNext,
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
                child: Text(
                  appText.retryQuiz,
                  style: TextStyle(fontSize: 11.sp),
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
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
          AppText.of(context).categoryQuiz,
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
            Text(
              AppText.of(context).overallScore,
              style: TextStyle(fontSize: 11.sp),
            ),
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
    final appText = AppText.of(context);
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
            correct ? appText.correctAnswers : appText.incorrectAnswers,
            style: TextStyle(fontSize: 12.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            correct
                ? appText.correctAnswersMessage
                : appText.incorrectAnswersMessage,
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
              correct
                  ? appText.viewCorrectAnswer
                  : appText.viewIncorrectAnswer,
              style: TextStyle(fontSize: 10.sp),
            ),
          ),
        ],
      ),
    );
  }
}
