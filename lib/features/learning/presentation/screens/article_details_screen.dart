import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/learning/domain/entities/article.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/bloc/article_detail_bloc.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/learning_failure_message.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/widgets/learning_widgets.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_formatters.dart';

/// One article in full. Expects an [ArticleDetailBloc] above it.
class ArticleDetailsScreen extends StatelessWidget {
  const ArticleDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<ArticleDetailBloc>().state;
    final article = state.article;

    final Widget body;
    switch (state.status) {
      case LearningLoadStatus.loading:
        body = const Center(child: CircularProgressIndicator());
      case LearningLoadStatus.failure:
        final notFound = state.failure?.statusCode == 404;
        body = Center(
          child: LearningMessage(
            message: learningFailureMessage(
              appText,
              state.failure,
              LearningResource.article,
            ),
            // Asking again will not bring back a removed article.
            onRetry: notFound
                ? null
                : () => context.read<ArticleDetailBloc>().add(
                    const LoadArticle(),
                  ),
          ),
        );
      case LearningLoadStatus.success:
        body = _ArticleBody(article: article!);
    }

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Column(
                children: [
                  LearningHeader(
                    title: appText.articlesDetails,
                    onBack: () => Navigator.maybePop(context),
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
            if (article != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
                  child: FilledButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.learningTest),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      minimumSize: Size(double.infinity, 55.h),
                    ),
                    child: Text(
                      appText.testLearning,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArticleBody extends StatelessWidget {
  const _ArticleBody({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final category = context.localized(article.categoryName);
    final date = articleDateLabel(context, article);
    final cover = article.coverImageUrl;
    final content = context.localized(article.content);
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 22.h, bottom: 91.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.localized(article.title),
            style: TextStyle(color: AppColor.primary, fontSize: 15.sp),
          ),
          if (category.isNotEmpty) ...[
            SizedBox(height: 9.h),
            ArticleTag(category),
          ],
          if (date != null) ...[
            SizedBox(height: 8.h),
            Text(
              date,
              style: TextStyle(color: AppColor.primary, fontSize: 12.sp),
            ),
          ],
          if (article.author.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              fillTemplate(appText.articleByAuthor, {'author': article.author}),
              style: TextStyle(
                color: context.inkColor(Color(0xFF718060)),
                fontSize: 12.sp,
              ),
            ),
          ],
          if (cover != null) ...[
            SizedBox(height: 9.h),
            ArticleCoverImage(url: cover, height: 170.h),
          ],
          SizedBox(height: 10.h),
          if (content.isEmpty)
            Text(
              appText.learningNoContent,
              style: TextStyle(fontSize: 12.sp, height: 1.45),
            )
          else
            ArticleMarkdown(markdown: content),
        ],
      ),
    );
  }
}
