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
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_sub_category.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_sub_categories.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_sub_category_reading_progress.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_reading_progress/hadith_reading_progress_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_sub_category/hadith_sub_category_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_detail_screen.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_list_scaffold.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_progress_ring.dart';

/// Route arguments for [HadithSubCategoryScreen].
class HadithSubCategoryArgs {
  const HadithSubCategoryArgs({required this.categoryId, this.title});

  final String categoryId;
  final String? title;
}

/// Sub-categories (chapters) of one hadith category
/// (`GET /hadiths/categories/{id}/subcategories`).
///
/// Reached by tapping a row on [HadithCategoryScreen]. Shows each
/// sub-category's name, hadith count and reading progress
/// (`GET /hadiths/reading/progress/sub-categories`, matched by id), with
/// search, pagination and shimmer loading placeholders.
class HadithSubCategoryScreen extends StatelessWidget {
  const HadithSubCategoryScreen({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  final String categoryId;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final repository = HadithLibraryRepositoryImpl(
      HadithLibraryRemoteDataSourceImpl(),
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              HadithSubCategoryBloc(GetHadithSubCategories(repository))
                ..add(LoadHadithSubCategories(categoryId)),
        ),
        BlocProvider(
          create: (_) => HadithReadingProgressBloc(
            GetHadithSubCategoryReadingProgress(repository).call,
          )..add(const LoadHadithReadingProgress()),
        ),
      ],
      child: _HadithSubCategoryView(categoryId: categoryId),
    );
  }
}

class _HadithSubCategoryView extends StatefulWidget {
  const _HadithSubCategoryView({required this.categoryId});

  final String categoryId;

  @override
  State<_HadithSubCategoryView> createState() => _HadithSubCategoryViewState();
}

class _HadithSubCategoryViewState extends State<_HadithSubCategoryView> {
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
      context.read<HadithSubCategoryBloc>().add(
        SearchHadithSubCategories(term),
      );
    });
  }

  /// Called when the user comes back from a sub-category's hadiths (where they
  /// may have read some), so the new percentages show straight away.
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
      context.read<HadithSubCategoryBloc>().add(
        const LoadMoreHadithSubCategories(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<HadithSubCategoryBloc>().state;
    // A first page too short to scroll would never fire the scroll listener,
    // so keep pulling pages until the list overflows (or runs out).
    if (state.status == HadithSubCategoryStatus.success &&
        state.hasMore &&
        !state.isLoadingMore &&
        state.loadMoreFailure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        if (_scrollController.position.maxScrollExtent <= 0) {
          context.read<HadithSubCategoryBloc>().add(
            const LoadMoreHadithSubCategories(),
          );
        }
      });
    }
    return HadithListScaffold(
      title: appText.hadithSubCategory,
      controller: _scrollController,
      onSearchChanged: _onSearchChanged,
      children: [
        if (state.isLoading)
          const _SubCategorySkeletons(count: 6)
        else if (state.status == HadithSubCategoryStatus.failure) ...[
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
            onPressed: () => context.read<HadithSubCategoryBloc>().add(
              LoadHadithSubCategories(widget.categoryId),
            ),
            child: Text(appText.tryAgain),
          ),
        ] else if (state.subCategories.isEmpty)
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
          for (final subCategory in state.subCategories) ...[
            _SubCategoryCard(
              subCategory: subCategory,
              hadithWord: appText.categoryHadith,
              onReturn: _refreshProgress,
            ),
            SizedBox(height: 10.h),
          ],
          if (state.isLoadingMore) const _SubCategorySkeletons(count: 2),
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
                  onPressed: () => context.read<HadithSubCategoryBloc>().add(
                    const LoadMoreHadithSubCategories(),
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

/// Shimmer placeholders shaped like [_SubCategoryCard], shown while the first
/// page or the next page is loading.
class _SubCategorySkeletons extends StatelessWidget {
  const _SubCategorySkeletons({required this.count});

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
              height: 72.h,
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

class _SubCategoryCard extends StatelessWidget {
  const _SubCategoryCard({
    required this.subCategory,
    required this.hadithWord,
    required this.onReturn,
  });

  final HadithSubCategory subCategory;
  final String hadithWord;

  /// Called after the hadith list opened from this card is closed.
  final VoidCallback onReturn;

  /// Always the Bangla name, falling back to `name` / the English name only
  /// when the API has no Bangla one.
  String get _title => [
    subCategory.nameBangla,
    subCategory.name,
    subCategory.nameEnglish,
  ].firstWhere((n) => n.isNotEmpty, orElse: () => '');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await Navigator.of(context).pushNamed(
          RouteNames.hadithDetail,
          arguments: HadithDetailArgs(
            subCategoryId: subCategory.id,
            title: _title,
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
              child: FittedBox(
                child: Padding(
                  padding: EdgeInsets.all(6.r),
                  child: Text(
                    '${subCategory.chapterNumber}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.inkColor(Color(0xFF2C3320)),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${formatHadithCount(subCategory.totalHadiths)} $hadithWord',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF9BA85B),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            HadithProgressRing(id: subCategory.id),
          ],
        ),
      ),
    );
  }
}
