import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/ayah_bookmark/ayah_bookmark_bloc.dart';

class AyahCard extends StatelessWidget {
  const AyahCard({
    super.key,
    required this.surahNo,
    required this.ayahNo,
    required this.surahName,
    required this.arabic,
    required this.translation,
  });

  final int surahNo;
  final int ayahNo;
  final String surahName;
  final String arabic;
  final String translation;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AyahBookmarkBloc(
        surahNo: surahNo,
        ayahNo: ayahNo,
        surahName: surahName,
        snippet: translation,
      )..add(const LoadBookmarkStatus()),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .85),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFDDE8C1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 13.r,
                  backgroundColor: const Color(0xFFDFE9B9),
                  child: Text(
                    '$ayahNo',
                    style: TextStyle(color: AppColor.primary, fontSize: 11.sp),
                  ),
                ),
                BlocBuilder<AyahBookmarkBloc, AyahBookmarkState>(
                  builder: (context, state) {
                    return InkWell(
                      onTap: () => context.read<AyahBookmarkBloc>().add(
                        const ToggleAyahBookmark(),
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Icon(
                          state.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: AppColor.primary,
                          size: 18.sp,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 19.sp, height: 1.8),
            ),
            if (translation.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Text(
                translation,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.4,
                  color: const Color(0xFF444444),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
