import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shows the complete list of quizzes a learner has finished.
class CompletedHistoryScreen extends StatelessWidget {
  const CompletedHistoryScreen({super.key});

  static const _results = [
    _QuizResult(title: 'Quiz 1 ( Quranic Science )', score: .67),
    _QuizResult(title: 'Quiz 2 ( Quranic Science )', score: .60),
    _QuizResult(title: 'Quiz 3 ( Quranic Science )', score: .60),
    _QuizResult(title: 'Quiz 4 ( Quranic Science )', score: .60),
    _QuizResult(title: 'Quiz 5 ( Quranic Science )', score: .60),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 69.h,
        leadingWidth: 58.w,
        leading:
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed:  () => Navigator.maybePop(context),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFDFDE68),
              foregroundColor: const Color(0xFF303629),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),

        title: Text(
          'Completed History',
          style: TextStyle(
            color: const Color(0xFF84945F),
            fontSize: 20.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 24.h),
        itemCount: _results.length,
        separatorBuilder: (_, _) => SizedBox(height: 8.h),
        itemBuilder: (context, index) =>
            _CompletedQuizCard(result: _results[index]),
      ),
    );
  }
}

class _CompletedQuizCard extends StatelessWidget {
  const _CompletedQuizCard({required this.result});

  final _QuizResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDE8C1)),
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDDE8C1)),
            ),
            child: Icon(
              Icons.image_outlined,
              color: const Color(0xFF8B9865),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.title, style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 6.h),
                Text(
                  '20 Questions',
                  style: TextStyle(
                    color: const Color(0xFFA1AD59),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          _HistoryScoreProgress(value: result.score),
        ],
      ),
    );
  }
}

class _HistoryScoreProgress extends StatelessWidget {
  const _HistoryScoreProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 57.w,
      height: 57.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 5.w,
            strokeCap: StrokeCap.round,
            color: const Color(0xFFA1AD59),
            backgroundColor: const Color(0xFFF0F0F6),
          ),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(color: const Color(0xFFA1AD59), fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}

class _QuizResult {
  const _QuizResult({required this.title, required this.score});

  final String title;
  final double score;
}
