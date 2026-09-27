import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_category.dart';
import 'package:islami_app_noorify/features/quiz/presentation/quiz_navigation.dart';

/// A quiz category on the Quiz home and completion screens. Explore starts a
/// practice quiz drawn from it.
class QuizCategoryCard extends StatelessWidget {
  const QuizCategoryCard({super.key, required this.category});

  final QuizCategory category;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final description = context.localized(category.description);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(19.w),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFDFE9B9)),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 27.r,
                height: 27.r,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColor.primary),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: QuizCategoryIcon(
                  iconUrl: category.iconUrl,
                  fallback: Icons.menu_book_outlined,
                  size: 16.sp,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => openCategoryQuiz(context, category),
                iconAlignment: IconAlignment.end,
                icon: Icon(Icons.north_east_rounded, size: 17.sp),
                label: Text(appText.explore),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.inkColor(Color(0xFF4D5542)),
                  side: const BorderSide(color: AppColor.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            context.localized(category.name),
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              description,
              style: TextStyle(
                fontSize: 11.sp,
                color: context.inkColor(Color(0xFF697269)),
              ),
            ),
          ],
          SizedBox(height: 14.h),
          Text(
            '${context.localized(category.totalQuestions.text)} '
            '${appText.questionsWord}',
            style: TextStyle(
              fontSize: 12.sp,
              color: context.inkColor(Color(0xFF56614F)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A category's `iconUrl` image, or [fallback] when there is none or it fails
/// to load.
class QuizCategoryIcon extends StatelessWidget {
  const QuizCategoryIcon({
    super.key,
    required this.iconUrl,
    required this.fallback,
    required this.size,
    this.color = AppColor.primary,
  });

  final String? iconUrl;
  final IconData fallback;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(fallback, size: size, color: color);
    final uri = iconUrl == null ? null : Uri.tryParse(iconUrl!);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return icon;
    return Center(
      child: Image.network(
        uri.toString(),
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => icon,
      ),
    );
  }
}
