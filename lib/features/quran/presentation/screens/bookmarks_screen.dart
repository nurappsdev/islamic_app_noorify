import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/bookmarks/bookmarks_bloc.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/quranBack.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 40.h,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.maybePop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFEDE7A6),
                              foregroundColor: AppColor.authLogo,
                            ),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                            ),
                          ),
                        ),
                        Text(
                          appText.bookmarksTitle,
                          style: TextStyle(
                            color: AppColor.primary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: BlocBuilder<BookmarksBloc, BookmarksState>(
                      builder: (context, state) {
                        if (state.isLoading && state.bookmarks.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColor.primary,
                            ),
                          );
                        }
                        final bookmarks = state.bookmarks;
                        if (bookmarks.isEmpty) {
                          return Center(
                            child: Text(
                              appText.noBookmarksYet,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13.sp,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: EdgeInsets.only(bottom: 20.h),
                          itemCount: bookmarks.length,
                          separatorBuilder: (_, _) => SizedBox(height: 9.h),
                          itemBuilder: (context, index) {
                            final bookmark = bookmarks[index];
                            return Material(
                              color: Colors.white.withValues(alpha: .85),
                              borderRadius: BorderRadius.circular(16.r),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16.r),
                                onTap: () => Navigator.of(context).pushNamed(
                                  RouteNames.quranSurahDetail,
                                  arguments: bookmark.surahNo,
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 13.h,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: const Color(0xFFDDE8C1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${bookmark.surahName} • '
                                              '${appText.ayahNoLabel} ${bookmark.ayahNo}',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (bookmark.snippet.isNotEmpty) ...[
                                              SizedBox(height: 4.h),
                                              Text(
                                                bookmark.snippet,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            context.read<BookmarksBloc>().add(
                                              RemoveBookmark(
                                                bookmark.surahNo,
                                                bookmark.ayahNo,
                                              ),
                                            ),
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: AppColor.primary,
                                          size: 20.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
