import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
// import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
// import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
// import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/bloc/quiz_bloc.dart';
// import 'package:tuhfatul_muslim/features/quiz/presentation/bloc/quiz_comparison_bloc.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_failure_message.dart';
// import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_comparison_card.dart';
// import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_formatters.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_attempt_card.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/widgets/quiz_status_view.dart';

/// Shows the complete list of quizzes a learner has finished, loading more as
/// the list is scrolled. Expects a [QuizBloc] above it.
class CompletedHistoryScreen extends StatelessWidget {
  const CompletedHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      appBar: AppBar(
        backgroundColor: context.surfaceColor(Colors.white),
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
              foregroundColor: Color(0xFF303629),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),

        title: Text(
          appText.completedHistory,
          style: TextStyle(
            color: context.inkColor(Color(0xFF84945F)),
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
              return QuizStatusView(
                message: quizFailureMessage(appText, state.failure),
                onRetry: () => context.read<QuizBloc>().add(
                  const LoadCompletedQuizHistory(),
                ),
              );
            case QuizStatus.success:
              if (state.attempts.isEmpty) {
                return ListView(
                  padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 24.h),
                  children: [
                    // const _HistoryComparison(),
                    QuizStatusView(message: appText.noQuizAttemptsYet),
                  ],
                );
              }
              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.extentAfter < 200) {
                    context.read<QuizBloc>().add(const LoadMoreQuizHistory());
                  }
                  return false;
                },
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 24.h),
                  // The attempts, then a loader while the next page is on its
                  // way. (With the comparison or summary card back: one more
                  // item each, and every index below shifts by one.)
                  itemCount:
                      state.attempts.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    // if (index == 0) return const _HistoryComparison();
                    // Summary (attempts, best and average score) - hidden for
                    // now; uncomment to show it.
                    // if (index == 0) {
                    //   return _HistorySummary(summary: state.summary);
                    // }
                    if (index >= state.attempts.length) {
                      return Padding(
                        padding: EdgeInsets.all(12.h),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    return QuizAttemptCard(
                      attempt: state.attempts[index],
                      showDate: true,
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}

// Summary card (attempts, best score, average score) - hidden for now;
// uncomment it and its use above to show it.
// /// The server's headline figures for the history.
// class _HistorySummary extends StatelessWidget {
//   const _HistorySummary({required this.summary});
//
//   final QuizAttemptSummary summary;
//
//   @override
//   Widget build(BuildContext context) {
//     final appText = AppText.of(context);
//     final items = [
//       (appText.attemptsLabel, '${summary.attempts}'),
//       (appText.bestScore, formatPercent(summary.bestScorePercentage)),
//       (appText.averageScore, formatPercent(summary.averageScorePercentage)),
//     ];
//     return Container(
//       padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
//       decoration: BoxDecoration(
//         color: context.surfaceColor(Color(0xFFDDE8BA)),
//         borderRadius: BorderRadius.circular(25.r),
//       ),
//       child: Row(
//         children: [
//           for (final (label, value) in items)
//             Expanded(
//               child: Column(
//                 children: [
//                   Text(
//                     context.localizedDigits(value),
//                     style: TextStyle(color: AppColor.primary, fontSize: 16.sp),
//                   ),
//                   SizedBox(height: 4.h),
//                   Text(
//                     label,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 11.sp),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// Comparison card - hidden for now; uncomment it, its imports, its uses
// above and its bloc in app_routes.dart to show it.
// /// The user against the leaderboard leader over the last week
// /// (`GET /quizzes/dashboard/history/compare`).
// class _HistoryComparison extends StatelessWidget {
//   const _HistoryComparison();
//
//   @override
//   Widget build(BuildContext context) {
//     final appText = AppText.of(context);
//     final state = context.watch<QuizComparisonBloc>().state;
//     final comparison = state.comparison;
//     switch (state.status) {
//       case QuizComparisonStatus.loading:
//         return Padding(
//           padding: EdgeInsets.all(16.h),
//           child: const Center(child: CircularProgressIndicator()),
//         );
//       case QuizComparisonStatus.failure:
//         return QuizStatusView(
//           message: quizFailureMessage(appText, state.failure),
//           onRetry: () => context.read<QuizComparisonBloc>().add(
//             const LoadQuizComparison(),
//           ),
//         );
//       case QuizComparisonStatus.success:
//         if (comparison == null) return const SizedBox.shrink();
//         return QuizComparisonCard(comparison: comparison);
//     }
//   }
// }
