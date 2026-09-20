import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/repositories/hadith_library_repository_impl.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_library_books.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_library/hadith_library_bloc.dart';
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
    return BlocProvider(
      create: (_) => HadithLibraryBloc(
        GetHadithLibraryBooks(
          HadithLibraryRepositoryImpl(HadithLibraryRemoteDataSourceImpl()),
        ),
      )..add(const LoadHadithLibrary()),
      child: const _HadithLibraryListView(),
    );
  }
}

class _HadithLibraryListView extends StatelessWidget {
  const _HadithLibraryListView();

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final state = context.watch<HadithLibraryBloc>().state;
    return HadithListScaffold(
      title: appText.hadithLibraryTitle,
      children: [
        if (state.isLoading)
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (state.status == HadithLibraryStatus.failure) ...[
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
            onPressed: () => context.read<HadithLibraryBloc>().add(
              const LoadHadithLibrary(),
            ),
            child: Text(appText.tryAgain),
          ),
        ] else
          for (final book in state.books) ...[
            _LibraryCard(book: book, appText: appText),
            SizedBox(height: 14.h),
          ],
      ],
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.book, required this.appText});

  final HadithLibraryBook book;
  final AppText appText;

  @override
  Widget build(BuildContext context) {
    final isBangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFDDE8AE)),
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
                  border: Border.all(
                    color: context.lineColor(Color(0xFF9BAE6C)),
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  size: 20.sp,
                  color: context.inkColor(Color(0xFF5F6E3E)),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => openHadithLibraryBook(context, book),
                iconAlignment: IconAlignment.end,
                icon: Icon(Icons.north_east_rounded, size: 15.sp),
                label: Text(appText.explore),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.inkColor(Color(0xFF4C5A34)),
                  side: BorderSide(color: context.lineColor(Color(0xFF9BAE6C))),
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
            (isBangla ? book.titleBn : book.titleEn).isEmpty
                ? book.titleEn
                : (isBangla ? book.titleBn : book.titleEn),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.inkColor(Color(0xFF2C3320)),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${appText.hadithTotalHadith} : ${formatHadithCount(book.totalHadiths)}',
            style: TextStyle(
              fontSize: 12.sp,
              color: context.inkColor(Color(0xFF5D6B44)),
            ),
          ),
        ],
      ),
    );
  }
}
