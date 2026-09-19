import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/repositories/hadith_library_repository_impl.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_categories.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_category/hadith_category_bloc.dart';
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
/// Bangla and/or the API's `name`) and hadith count.
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
    return BlocProvider(
      create: (_) => HadithCategoryBloc(
        GetHadithCategories(
          HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl()),
        ),
      )..add(LoadHadithCategories(bookId)),
      child: _HadithCategoryView(bookId: bookId),
    );
  }
}

class _HadithCategoryView extends StatelessWidget {
  const _HadithCategoryView({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<HadithCategoryBloc>().state;
    return HadithListScaffold(
      title: appText.hadithCategory,
      children: [
        if (state.isLoading)
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (state.status == HadithCategoryStatus.failure) ...[
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: Text(
              state.failure?.message ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF5D6B44)),
            ),
          ),
          TextButton(
            onPressed: () => context.read<HadithCategoryBloc>().add(
              LoadHadithCategories(bookId),
            ),
            child: Text(appText.tryAgain),
          ),
        ] else
          for (var i = 0; i < state.categories.length; i++) ...[
            _CategoryCard(
              index: i + 1,
              category: state.categories[i],
              hadithWord: appText.categoryHadith,
            ),
            SizedBox(height: 10.h),
          ],
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.index,
    required this.category,
    required this.hadithWord,
  });

  final int index;
  final HadithCategory category;
  final String hadithWord;

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

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE3E7D3)),
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
                    color: const Color(0xFF2C3320),
                  ),
                ),
                if (showSecondary) ...[
                  SizedBox(height: 2.h),
                  Text(
                    secondary,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF5D6B44),
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
        ],
      ),
    );
  }
}
