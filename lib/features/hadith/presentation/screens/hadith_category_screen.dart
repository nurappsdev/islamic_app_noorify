import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/repositories/hadith_library_repository_impl.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_categories.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_reading_progress.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_category/hadith_category_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_reading_progress/hadith_reading_progress_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_sub_category_screen.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_list_scaffold.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// Route arguments for [HadithCategoryScreen].
class HadithCategoryArgs {
  const HadithCategoryArgs({required this.bookId, this.title});

  final String bookId;
  final String? title;
}

/// Per-collection Hadith category list (`GET /hadiths/categories`).
///
/// Reached from a collection card's "Explore" action on the Hadith library
/// screens. Shows the collection's ordered categories, each with its name (in
/// Bangla and/or the API's `name`), hadith count and reading progress
/// (`GET /hadiths/reading/progress/categories`, matched by category id).
class HadithCategoryScreen extends StatelessWidget {
  const HadithCategoryScreen({
    super.key,
    required this.bookId,
    this.collectionName,
  });

  final String bookId;
  final String? collectionName;

  @override
  Widget build(BuildContext context) {
    final repository = HadithLibraryRepositoryImpl(
      HadithLibraryRemoteDataSourceImpl(),
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              HadithCategoryBloc(GetHadithCategories(repository))
                ..add(LoadHadithCategories(bookId)),
        ),
        BlocProvider(
          create: (_) =>
              HadithReadingProgressBloc(GetHadithReadingProgress(repository))
                ..add(const LoadHadithReadingProgress()),
        ),
      ],
      child: _HadithCategoryView(bookId: bookId),
    );
  }
}

class _HadithCategoryView extends StatefulWidget {
  const _HadithCategoryView({required this.bookId});

  final String bookId;

  @override
  State<_HadithCategoryView> createState() => _HadithCategoryViewState();
}

class _HadithCategoryViewState extends State<_HadithCategoryView> {
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
      context.read<HadithCategoryBloc>().add(SearchHadithCategories(term));
    });
  }

  /// Called when the user comes back from a category's screens (where they
  /// may have read hadiths), so the new percentages show straight away.
  void _refreshProgress() {
    if (!mounted) return;
    context.read<HadithReadingProgressBloc>().add(
      const RefreshHadithReadingProgress(),
    );
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      // The bloc ignores this while a page is loading or after the last one.
      context.read<HadithCategoryBloc>().add(const LoadMoreHadithCategories());
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<HadithCategoryBloc>().state;
    // A first page too short to scroll would never fire the scroll listener,
    // so keep pulling pages until the list overflows (or runs out).
    if (state.status == HadithCategoryStatus.success &&
        state.hasMore &&
        !state.isLoadingMore &&
        state.loadMoreFailure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        if (_scrollController.position.maxScrollExtent <= 0) {
          context.read<HadithCategoryBloc>().add(
            const LoadMoreHadithCategories(),
          );
        }
      });
    }
    return HadithListScaffold(
      title: appText.hadithCategory,
      controller: _scrollController,
      onSearchChanged: _onSearchChanged,
      children: [
        if (state.isLoading)
          const _CategorySkeletons(count: 6)
        else if (state.status == HadithCategoryStatus.failure) ...[
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: Text(
              state.failure?.message ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: context.inkColor(Color(0xFF5D6B44)),
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.read<HadithCategoryBloc>().add(
              LoadHadithCategories(widget.bookId),
            ),
            child: Text(appText.tryAgain),
          ),
        ] else if (state.categories.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: Text(
              appText.noResultsFound,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: context.inkColor(Color(0xFF5D6B44)),
              ),
            ),
          )
        else ...[
          for (var i = 0; i < state.categories.length; i++) ...[
            _CategoryCard(
              index: i + 1,
              category: state.categories[i],
              hadithWord: appText.categoryHadith,
              onReturn: _refreshProgress,
            ),
            SizedBox(height: 10.h),
          ],
          if (state.isLoadingMore) const _CategorySkeletons(count: 2),
          if (state.loadMoreFailure != null)
            Column(
              children: [
                Text(
                  state.loadMoreFailure!.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: context.inkColor(Color(0xFF5D6B44)),
                  ),
                ),
                TextButton(
                  onPressed: () => context.read<HadithCategoryBloc>().add(
                    const LoadMoreHadithCategories(),
                  ),
                  child: Text(appText.tryAgain),
                ),
              ],
            ),
        ],
      ],
    );
  }
}

/// Shimmer placeholders shaped like [_CategoryCard], shown while the first
/// page or the next page is loading.
class _CategorySkeletons extends StatelessWidget {
  const _CategorySkeletons({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.surfaceColor(Color(0xFFE3ECC5)),
      highlightColor: context.surfaceColor(Color(0xFFF6F9EC)),
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            Container(
              height: 68.h,
              decoration: BoxDecoration(
                color: context.surfaceColor(Colors.white),
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.index,
    required this.category,
    required this.hadithWord,
    required this.onReturn,
  });

  final int index;
  final HadithCategory category;
  final String hadithWord;

  /// Called once the pushed sub-category route has been popped.
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final isBangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    // The language's own name first, falling back to the other when empty;
    // the other one is shown underneath when it actually differs.
    final primary = isBangla
        ? (category.nameBangla.isEmpty ? category.name : category.nameBangla)
        : (category.name.isEmpty ? category.nameBangla : category.name);
    final secondary = isBangla ? category.name : category.nameBangla;
    final showSecondary = secondary.isNotEmpty && secondary != primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await Navigator.of(context).pushNamed(
          RouteNames.hadithSubCategory,
          arguments: HadithSubCategoryArgs(
            categoryId: category.id,
            title: primary,
          ),
        );
        onReturn();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(Colors.white),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: context.lineColor(Color(0xFFE3E7D3))),
        ),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF8B9A4B),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$index',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primary,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: context.inkColor(Color(0xFF2C3320)),
                    ),
                  ),
                  if (showSecondary) ...[
                    SizedBox(height: 2.h),
                    Text(
                      secondary,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.inkColor(Color(0xFF5D6B44)),
                      ),
                    ),
                  ],
                  SizedBox(height: 4.h),
                  Text(
                    '${formatHadithCount(category.totalHadiths)} $hadithWord',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF9BA85B),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            _CategoryProgressRing(categoryId: category.id),
          ],
        ),
      ),
    );
  }
}

/// The reading progress of one category: a ring filled to the backend's
/// `percentage`, with the number inside. Shows 0% when the backend has no
/// progress for the category (or the request failed), and an empty ring
/// while the first load is running.
class _CategoryProgressRing extends StatelessWidget {
  const _CategoryProgressRing({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    // Rebuild only when this category's own value changes.
    final (isLoading, percentage) = context
        .select<HadithReadingProgressBloc, (bool, double?)>(
          (bloc) => (
            bloc.state.isLoading && bloc.state.progress == null,
            bloc.state.forCategory(categoryId)?.percentage,
          ),
        );
    final clamped = (percentage ?? 0).clamp(0, 100).toDouble();
    final size = 40.r;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            // Full ring = the remaining portion; the arc drawn over it is the
            // read portion.
            value: isLoading ? 0 : clamped / 100,
            strokeWidth: 3.5.r,
            strokeCap: clamped > 0 ? StrokeCap.round : null,
            backgroundColor: context.lineColor(const Color(0xFFE3E7D3)),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF8B9A4B)),
          ),
          if (!isLoading)
            Center(
              child: Text(
                '${clamped.round()}%',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: context.inkColor(const Color(0xFF2C3320)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
