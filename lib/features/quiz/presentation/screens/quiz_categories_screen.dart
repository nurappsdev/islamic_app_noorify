import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/app_route_observer.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/presentation/bloc/quiz_categories_bloc.dart';
import 'package:islami_app_noorify/features/quiz/presentation/cubit/daily_quiz_status_cubit.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_formatters.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_navigation.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_category_card.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_status_view.dart';

/// Quiz home: today's challenge plus the first few categories. Expects a
/// [QuizCategoriesBloc] and optional [DailyQuizStatusCubit] above it.
class QuizCategoriesScreen extends StatefulWidget {
  const QuizCategoriesScreen({super.key});

  /// How many categories the home shows; See All lists the rest.
  static const _previewCount = 3;

  @override
  State<QuizCategoriesScreen> createState() => _QuizCategoriesScreenState();
}

class _QuizCategoriesScreenState extends State<QuizCategoriesScreen>
    with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<DailyQuizStatusCubit?>()?.load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              Future.sync(
                () => context.read<QuizCategoriesBloc>().add(
                  const LoadQuizCategories(),
                ),
              ),
              context.read<DailyQuizStatusCubit?>()?.load(silent: true) ??
                  Future.value(),
            ]);
          },
          child: ListView(
            padding: EdgeInsets.only(bottom: 90.h),
            children: [
              const _QuizHero(),
              Padding(
                padding: EdgeInsets.fromLTRB(23.w, 24.h, 23.w, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appText.categories,
                      style: TextStyle(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(RouteNames.quizList),
                      child: Text(
                        appText.seeAll,
                        style: TextStyle(
                          color: context.inkColor(Colors.black),
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const QuizCategoryPreview(count: QuizCategoriesScreen._previewCount),
            ],
          ),
        ),
      ),
    );
  }
}

/// The first [count] categories from the nearest [QuizCategoriesBloc], with
/// its loading, error and empty states.
class QuizCategoryPreview extends StatelessWidget {
  const QuizCategoryPreview({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<QuizCategoriesBloc>().state;
    switch (state.status) {
      case QuizCategoriesStatus.initial:
      case QuizCategoriesStatus.loading:
        return Padding(
          padding: EdgeInsets.all(24.h),
          child: const Center(child: CircularProgressIndicator()),
        );
      case QuizCategoriesStatus.failure:
        return QuizStatusView(
          message: appText.unableToLoadQuizCategories,
          onRetry: () => context.read<QuizCategoriesBloc>().add(
            const LoadQuizCategories(),
          ),
        );
      case QuizCategoriesStatus.success:
        if (state.categories.isEmpty) {
          return QuizStatusView(message: appText.noQuizCategories);
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Column(
            children: [
              for (final category in state.categories.take(count)) ...[
                QuizCategoryCard(category: category),
                SizedBox(height: 9.h),
              ],
            ],
          ),
        );
    }
  }
}

class _QuizHero extends StatelessWidget {
  const _QuizHero();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final dailyState = context.watch<DailyQuizStatusCubit?>()?.state;
    final dailyStatus = dailyState?.dailyStatus;
    final isCompleted = dailyStatus?.completed ?? false;

    return Container(
      height: 250.h,
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 26.w, 30.h),
      decoration: BoxDecoration(
        // CSS `linear-gradient(270deg, #E6E6E6 0%, #DCE8B8 100%)`: 270deg
        // runs right to left.
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            context.surfaceColor(const Color(0xFFE6E6E6)),
            context.surfaceColor(const Color(0xFFDCE8B8)),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(38.r),
          bottomRight: Radius.circular(38.r),
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFDFDE68),
                foregroundColor: const Color(0xFF303629),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            ),
          ),
          Positioned(
            left: 22.w,
            bottom: isCompleted ? 14.h : 6.h,
            child: SizedBox(
              width: 176.w,
              child: isCompleted
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appText.youCompletedTodaysChallenge,
                          style: TextStyle(
                            color: context.inkColor(const Color(0xFF84945F)),
                            fontSize: 21.sp,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Image.asset(
                              'assets/quiz_reading_icon.png',
                              width: 48.r,
                              height: 48.r,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                context.localizedDigits(
                                  '${appText.todaysPointsLabel} : ${formatPoints(dailyStatus!.displayPoints)}',
                                ),
                                style: TextStyle(
                                  color: context.inkColor(
                                    const Color(0xFF84945F),
                                  ),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appText.completeTodaysChallenge,
                          style: TextStyle(
                            color: AppColor.primary,
                            fontSize: 22.sp,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        FilledButton(
                          onPressed: () async {
                            await openDailyQuiz(context);
                            if (context.mounted) {
                              context
                                  .read<DailyQuizStatusCubit?>()
                                  ?.load(silent: true);
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: 18.w,
                              vertical: 11.h,
                            ),
                          ),
                          child: Text(
                            appText.letsGetStart,
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: isCompleted
                ? Image.asset(
                    'assets/quiz_completed.png',
                    width: 140.w,
                    height: 140.w,
                    fit: BoxFit.contain,
                  )
                : Image.asset(
                    'assets/quiz.png',
                    width: 130.w,
                    height: 130.w,
                    fit: BoxFit.contain,
                  ),
          ),
        ],
      ),
    );
  }
}

