import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/widgets/hadith_list_scaffold.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/bloc/articles_bloc.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/learning_failure_message.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/widgets/learning_widgets.dart';

/// One category's articles, or all of them, with search and infinite
/// scroll. Expects an [ArticlesBloc] above it.
class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  /// How close to the end of the list (in logical pixels) the next page
  /// starts loading.
  static const _loadMoreThreshold = 240.0;

  static const _searchDebounce = Duration(milliseconds: 400);

  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Waits for a pause in typing before hitting the API.
  void _onSearchChanged(String term) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (!mounted) return;
      context.read<ArticlesBloc>().add(SearchArticles(term));
    });
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      // The bloc ignores this while a page is loading or after the last one.
      context.read<ArticlesBloc>().add(const LoadMoreArticles());
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final bloc = context.read<ArticlesBloc>();
    final state = context.watch<ArticlesBloc>().state;
    final category = bloc.scope.category;
    final description = category == null
        ? ''
        : context.localized(category.description);

    // A first page too short to scroll would never fire the scroll listener,
    // so keep pulling pages until the list overflows (or runs out).
    if (state.canLoadMore && state.loadMoreFailure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        if (_scrollController.position.maxScrollExtent <= 0) {
          bloc.add(const LoadMoreArticles());
        }
      });
    }

    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 24.h),
              children: [
                LearningHeader(
                  title: category == null
                      ? appText.allArticles
                      : context.localized(category.name),
                  onBack: () => Navigator.maybePop(context),
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.inkColor(Color(0xFF718060)),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                HadithSearchField(
                  hint: appText.learningSearchArticles,
                  onChanged: _onSearchChanged,
                ),
                SizedBox(height: 16.h),
                ..._results(context, state),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: Container(
                  height: 126.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        context.pageColor(const Color(0xFFE4EDBF)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(BuildContext context, ArticlesState state) {
    final appText = AppText.of(context);
    final bloc = context.read<ArticlesBloc>();
    switch (state.status) {
      case LearningLoadStatus.loading:
        return [
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ];
      case LearningLoadStatus.failure:
        return [
          LearningMessage(
            message: learningFailureMessage(
              appText,
              state.failure,
              LearningResource.articles,
            ),
            onRetry: () => bloc.add(const LoadArticles()),
          ),
        ];
      case LearningLoadStatus.success:
        if (state.items.isEmpty) {
          return [
            LearningMessage(
              message: state.searchTerm.isEmpty
                  ? appText.learningNoArticles
                  : appText.learningNoSearchResults,
            ),
          ];
        }
    }
    return [
      for (final article in state.items) ...[
        ArticleCard(
          article: article,
          onTap: () => Navigator.of(
            context,
          ).pushNamed(RouteNames.learningArticleDetails, arguments: article.id),
        ),
        SizedBox(height: 7.h),
      ],
      if (state.isLoadingMore)
        Padding(
          padding: EdgeInsets.all(12.h),
          child: const Center(child: CircularProgressIndicator()),
        )
      else if (state.loadMoreFailure != null)
        LearningMessage(
          message: learningFailureMessage(
            appText,
            state.loadMoreFailure,
            LearningResource.articles,
          ),
          onRetry: () => bloc.add(const LoadMoreArticles()),
        ),
      // Room to scroll the last card clear of the fade.
      SizedBox(height: 90.h),
    ];
  }
}
