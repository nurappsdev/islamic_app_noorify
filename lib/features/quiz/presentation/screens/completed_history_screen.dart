import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_history_item.dart';
import 'package:islami_app_noorify/features/quiz/presentation/bloc/quiz_bloc.dart';

/// Shows the complete list of quizzes a learner has finished.
class CompletedHistoryScreen extends StatelessWidget {
  const CompletedHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 69.h,
        leadingWidth: 58.w,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFDFDE68),
              foregroundColor: const Color(0xFF303629),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),

        title: Text(
          appText.completedHistory,
          style: TextStyle(
            color: const Color(0xFF84945F),
            fontSize: 20.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: BlocBuilder<QuizBloc, QuizState>(
        builder: (context, state) {
          switch (state.status) {
            case QuizStatus.initial:
            case QuizStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case QuizStatus.failure:
              return _HistoryLoadFailure(
                message: state.errorMessage ?? appText.unableToLoadQuizHistory,
              );
            case QuizStatus.success:
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 24.h),
                itemCount: state.completedHistory.length,
                separatorBuilder: (_, _) => SizedBox(height: 8.h),
                itemBuilder: (context, index) =>
                    _CompletedQuizCard(result: state.completedHistory[index]),
              );
          }
        },
      ),
    );
  }
}

class _CompletedQuizCard extends StatelessWidget {
  const _CompletedQuizCard({required this.result});

  final QuizHistoryItem result;

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
                  '${result.questionCount} ${AppText.of(context).questionsWord}',
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

class _HistoryLoadFailure extends StatelessWidget {
  const _HistoryLoadFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: 12.h),
            OutlinedButton(
              onPressed: () => context.read<QuizBloc>().add(
                const LoadCompletedQuizHistory(),
              ),
              child: Text(AppText.of(context).tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
