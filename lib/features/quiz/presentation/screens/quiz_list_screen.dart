import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_category.dart';
import 'package:islami_app_noorify/features/quiz/presentation/bloc/quiz_categories_bloc.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_navigation.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_category_card.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_status_view.dart';

/// Every quiz category; tapping one starts a practice quiz drawn from it.
/// Expects a [QuizCategoriesBloc] above it.
class QuizListScreen extends StatelessWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 0),
          child: Column(
            children: [
              _QuizListHeader(onBack: () => Navigator.maybePop(context)),
              SizedBox(height: 12.h),
              Expanded(
                child: BlocBuilder<QuizCategoriesBloc, QuizCategoriesState>(
                  builder: (context, state) {
                    final appText = AppText.of(context);
                    switch (state.status) {
                      case QuizCategoriesStatus.initial:
                      case QuizCategoriesStatus.loading:
                        return const Center(child: CircularProgressIndicator());
                      case QuizCategoriesStatus.failure:
                        return QuizStatusView(
                          message: appText.unableToLoadQuizCategories,
                          onRetry: () => context.read<QuizCategoriesBloc>().add(
                            const LoadQuizCategories(),
                          ),
                        );
                      case QuizCategoriesStatus.success:
                        if (state.categories.isEmpty) {
                          return QuizStatusView(
                            message: appText.noQuizCategories,
                          );
                        }
                        return ListView.separated(
                          itemCount: state.categories.length,
                          separatorBuilder: (_, _) => SizedBox(height: 7.h),
                          itemBuilder: (context, index) {
                            final category = state.categories[index];
                            return _QuizListTile(
                              category: category,
                              onTap: () => openCategoryQuiz(context, category),
                            );
                          },
                        );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizListHeader extends StatelessWidget {
  const _QuizListHeader({required this.onBack});
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
              foregroundColor: Color(0xFF303629),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        Text(
          AppText.of(context).categories,
          style: TextStyle(color: AppColor.primary, fontSize: 18.sp),
        ),
      ],
    ),
  );
}

class _QuizListTile extends StatelessWidget {
  const _QuizListTile({required this.category, required this.onTap});
  final QuizCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Material(
      color: context.surfaceColor(Colors.white),
      borderRadius: BorderRadius.circular(22.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          height: 75.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            border: Border.all(color: context.lineColor(Color(0xFFDDE8B5))),
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Row(
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.lineColor(Color(0xFFDDE8B5)),
                  ),
                ),
                child: QuizCategoryIcon(
                  iconUrl: category.iconUrl,
                  fallback: Icons.image_outlined,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.localized(category.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(height: 7.h),
                    Text(
                      '${context.localized(category.totalQuestions.text)} '
                      '${appText.questionsWord}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColor.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
