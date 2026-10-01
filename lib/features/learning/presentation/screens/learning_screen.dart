import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/learning/domain/entities/article.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/bloc/article_categories_bloc.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/bloc/articles_bloc.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/learning_failure_message.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/widgets/learning_widgets.dart';

/// The Learn tab: article categories to explore, then the latest articles.
/// Expects an [ArticleCategoriesBloc] and an [ArticlesBloc] (all articles)
/// above it.
class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    final categories = context.read<ArticleCategoriesBloc>();
    final articles = context.read<ArticlesBloc>();
    categories.add(const LoadArticleCategories());
    articles.add(const LoadArticles());
    await Future.wait([
      categories.stream.firstWhere((s) => !s.isLoading),
      articles.stream.firstWhere((s) => !s.isLoading),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView(
            padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 89.h),
            children: [
              LearningHeader(
                title: appText.learning,
                onBack: () => Navigator.maybePop(context),
              ),
              SizedBox(height: 22.h),
              _SectionTitle(appText.explore),
              SizedBox(height: 15.h),
              const _ExploreRow(),
              SizedBox(height: 21.h),
              _SectionTitle(
                appText.recentArticles,
                onSeeAll: () => Navigator.of(context).pushNamed(
                  RouteNames.learningArticles,
                  arguments: const ArticleListScope.all(),
                ),
              ),
              SizedBox(height: 17.h),
              const _RecentArticles(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
        ),
      ),
      if (onSeeAll != null)
        TextButton(
          onPressed: onSeeAll,
          child: Text(
            AppText.of(context).seeAll,
            style: TextStyle(
              color: context.inkColor(Colors.black),
              fontSize: 12.sp,
            ),
          ),
        ),
    ],
  );
}

/// Tall enough for a two-line category name above the count and button.
double get _exploreCardHeight => 152.h;

/// The categories, side by side; the next page loads near the end.
class _ExploreRow extends StatefulWidget {
  const _ExploreRow();

  @override
  State<_ExploreRow> createState() => _ExploreRowState();
}

class _ExploreRowState extends State<_ExploreRow> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Fetches the next page once the end is near. The bloc ignores this while
  /// a page is loading or after the last one.
  void _maybeLoadMore() {
    if (!_controller.hasClients) return;
    if (_controller.position.extentAfter < 200) {
      context.read<ArticleCategoriesBloc>().add(
        const LoadMoreArticleCategories(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bloc = context.read<ArticleCategoriesBloc>();
    final state = context.watch<ArticleCategoriesBloc>().state;
    switch (state.status) {
      case LearningLoadStatus.loading:
        return SizedBox(
          height: _exploreCardHeight,
          child: const Center(child: CircularProgressIndicator()),
        );
      case LearningLoadStatus.failure:
        return LearningMessage(
          message: learningFailureMessage(
            appText,
            state.failure,
            LearningResource.categories,
          ),
          onRetry: () => bloc.add(const LoadArticleCategories()),
        );
      case LearningLoadStatus.success:
        if (state.items.isEmpty) {
          return LearningMessage(message: appText.learningNoCategories);
        }
    }
    // A first page too narrow to scroll would never reach the end.
    if (state.canLoadMore && state.loadMoreFailure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeLoadMore();
      });
    }
    final showTrailer = state.isLoadingMore || state.loadMoreFailure != null;
    return SizedBox(
      height: _exploreCardHeight,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: state.items.length + (showTrailer ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < state.items.length) {
            return _ExploreCard(category: state.items[index]);
          }
          if (state.isLoadingMore) {
            return SizedBox(
              width: 60.w,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          return IconButton(
            tooltip: appText.tryAgain,
            onPressed: () => bloc.add(const LoadMoreArticleCategories()),
            icon: const Icon(Icons.refresh_rounded),
          );
        },
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.category});
  final ArticleCategory category;

  void _open(BuildContext context) => Navigator.of(context).pushNamed(
    RouteNames.learningArticles,
    arguments: ArticleListScope.category(category),
  );

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      width: 147.w,
      margin: EdgeInsets.only(right: 8.w),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 10.w, 14.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFDFE9B9)),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gets most of the free space, so two lines fit; only a very
          // long name (or large system text) is cut short.
          Flexible(
            flex: 4,
            child: Text(
              context.localized(category.name),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            context.localizedDigits(
              '${category.totalArticles} ${appText.articlesCountLabel}',
            ),
            style: TextStyle(
              color: context.inkColor(Color(0xFF718060)),
              fontSize: 12.sp,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _open(context),
            iconAlignment: IconAlignment.end,
            icon: Icon(Icons.north_east_rounded, size: 16.sp),
            label: Text(
              appText.explore,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.inkColor(Color(0xFF637354)),
              side: const BorderSide(color: AppColor.primary),
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              minimumSize: Size(0, 34.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The first few articles; See All opens the whole list.
class _RecentArticles extends StatelessWidget {
  const _RecentArticles();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<ArticlesBloc>().state;
    switch (state.status) {
      case LearningLoadStatus.loading:
        return Padding(
          padding: EdgeInsets.all(24.h),
          child: const Center(child: CircularProgressIndicator()),
        );
      case LearningLoadStatus.failure:
        return LearningMessage(
          message: learningFailureMessage(
            appText,
            state.failure,
            LearningResource.articles,
          ),
          onRetry: () => context.read<ArticlesBloc>().add(const LoadArticles()),
        );
      case LearningLoadStatus.success:
        if (state.items.isEmpty) {
          return LearningMessage(message: appText.learningNoArticles);
        }
        return Column(
          children: [
            for (final article in state.items) ...[
              ArticleCard(
                article: article,
                onTap: () => Navigator.of(context).pushNamed(
                  RouteNames.learningArticleDetails,
                  arguments: article.id,
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ],
        );
    }
  }
}
