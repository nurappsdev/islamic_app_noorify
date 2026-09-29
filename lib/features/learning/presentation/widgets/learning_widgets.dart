import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/learning/domain/entities/article.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_formatters.dart';

// The pieces the Learning screens share.

/// Lime back button with a centred title.
class LearningHeader extends StatelessWidget {
  const LearningHeader({super.key, required this.title, required this.onBack});

  final String title;
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
              foregroundColor: Color(0xFF303629),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 48.w),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColor.primary, fontSize: 18.sp),
          ),
        ),
      ],
    ),
  );
}

/// "Published: 27 September 2026", in the app's language.
String? articleDateLabel(BuildContext context, Article article) {
  final date = article.displayDate;
  if (date == null) return null;
  final appText = AppText.of(context);
  return context.localizedDigits(
    fillTemplate(appText.articlePublishedOn, {
      'date': formatQuizDay(date, appText.monthNames),
    }),
  );
}

/// The category name in a rounded outline.
class ArticleTag extends StatelessWidget {
  const ArticleTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(
      border: Border.all(color: context.lineColor(Color(0xFFDDE8B5))),
      borderRadius: BorderRadius.circular(15.r),
    ),
    child: Text(label, style: TextStyle(fontSize: 11.sp)),
  );
}

/// An article's cover from [url], with a placeholder while it loads or when
/// it cannot be shown.
class ArticleCoverImage extends StatelessWidget {
  const ArticleCoverImage({super.key, required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget placeholder({bool loading = false}) => Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      color: context.surfaceColor(Color(0xFFF2F6E7)),
      child: loading
          ? const CircularProgressIndicator(strokeWidth: 2)
          : Icon(
              Icons.image_not_supported_outlined,
              color: context.inkColor(Color(0xFFB0C573)),
            ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Image.network(
        url,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder(loading: true),
        errorBuilder: (_, _, _) => placeholder(),
      ),
    );
  }
}

/// An article in a list: title, category, cover, excerpt and date.
class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final category = context.localized(article.categoryName);
    final excerpt = context.localized(article.excerpt);
    final date = articleDateLabel(context, article);
    final cover = article.coverImageUrl;
    return Material(
      color: context.surfaceColor(Color(0xFFF2F6E7)),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.fromLTRB(8.w, 10.h, 8.w, 10.h),
          decoration: BoxDecoration(
            border: Border.all(color: context.lineColor(Color(0xFFDDE8B5))),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.localized(article.title),
                style: TextStyle(color: AppColor.primary, fontSize: 14.sp),
              ),
              if (category.isNotEmpty) ...[
                SizedBox(height: 7.h),
                ArticleTag(category),
              ],
              if (cover != null) ...[
                SizedBox(height: 7.h),
                ArticleCoverImage(url: cover, height: 160.h),
              ],
              if (excerpt.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Text(
                  excerpt,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.sp, height: 1.45),
                ),
              ],
              SizedBox(height: 8.h),
              Text(
                appText.seeMore,
                style: TextStyle(
                  color: AppColor.primary,
                  decoration: TextDecoration.underline,
                  fontSize: 12.sp,
                ),
              ),
              if (date != null) ...[
                SizedBox(height: 8.h),
                Text(
                  date,
                  style: TextStyle(
                    color: const Color(0xFFB0C573),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A centred message with an optional Try Again button.
class LearningMessage extends StatelessWidget {
  const LearningMessage({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 24.h),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.sp),
        ),
        if (onRetry != null) ...[
          SizedBox(height: 12.h),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(AppText.of(context).tryAgain),
          ),
        ],
      ],
    ),
  );
}

/// Turns an article's Markdown into HTML. Raw HTML in the source is shown
/// as text rather than rendered.
String articleMarkdownToHtml(String markdown) => md.markdownToHtml(
  markdown.replaceAll('<', '&lt;'),
  extensionSet: md.ExtensionSet.gitHubFlavored,
);

/// An article's Markdown content, rendered.
class ArticleMarkdown extends StatelessWidget {
  const ArticleMarkdown({super.key, required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) => HtmlWidget(
    articleMarkdownToHtml(markdown),
    textStyle: TextStyle(fontSize: 13.sp, height: 1.5),
    customStylesBuilder: (element) => switch (element.localName) {
      // AppColor.primary.
      'h1' || 'h2' || 'h3' => {'color': '#A1AD59'},
      _ => null,
    },
    onTapUrl: (url) {
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
        return true;
      }
      launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    },
  );
}
