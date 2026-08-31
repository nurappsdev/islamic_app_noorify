import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_book_catalog.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_book.dart';
import 'package:islami_app_noorify/features/hadith/presentation/widgets/hadith_list_scaffold.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// Full "Hadith Library" collection list.
///
/// Reached from the "See All" action next to the Hadith Library section on
/// [HadithLibraryScreen]. Each card's "Explore" action opens the book reader
/// for that collection.
class HadithLibraryListScreen extends StatelessWidget {
  const HadithLibraryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return HadithListScaffold(
      title: appText.hadithLibraryTitle,
      children: [
        for (final book in HadithBookCatalog.libraryCollections) ...[
          _LibraryCard(book: book, appText: appText),
          SizedBox(height: 14.h),
        ],
      ],
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.book, required this.appText});

  final HadithBook book;
  final AppText appText;

  @override
  Widget build(BuildContext context) {
    final isBangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE8AE),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF9BAE6C)),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  size: 20.sp,
                  color: const Color(0xFF5F6E3E),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => openHadithCollection(context, book),
                iconAlignment: IconAlignment.end,
                icon: Icon(Icons.north_east_rounded, size: 15.sp),
                label: Text(appText.explore),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4C5A34),
                  side: const BorderSide(color: Color(0xFF9BAE6C)),
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  minimumSize: Size(0, 36.h),
                  textStyle: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            isBangla ? book.titleBn : book.titleEn,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3320),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${appText.hadithTotalHadith} : ${book.hadithCount}',
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF5D6B44)),
          ),
        ],
      ),
    );
  }
}
