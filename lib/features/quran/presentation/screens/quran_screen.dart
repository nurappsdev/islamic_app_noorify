import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_bottom_nav.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  static List<_Surah> _surahs(AppText appText) => [
    _Surah('Al-Fatihah', appText.surahMeaningOpening, 7),
    _Surah('Al-Baqarah', appText.surahMeaningCow, 286),
    _Surah('Al-Imran', appText.surahMeaningFamilyOfImran, 200),
    _Surah('An-Nisa', appText.surahMeaningWomen, 176),
  ];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final surahs = _surahs(appText);
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
            child: ListView(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 92.h),
              children: [
                Center(
                  child: Text(
                    appText.categoryQuran,
                    style: TextStyle(
                      color: AppColor.primary,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Center(
                  child: Image.asset(
                    'assets/images/bismillah.png',
                    height: 34.h,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 14.h),
                Center(
                  child: Image.asset(
                    'assets/images/Quran.png',
                    height: 148.h,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 22.h),
                TextField(
                  style: TextStyle(fontSize: 13.sp),
                  decoration: InputDecoration(
                    hintText: appText.searchSurah,
                    hintStyle: TextStyle(
                      color: const Color(0xFFB8B8B8),
                      fontSize: 13.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColor.primary,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: Color(0xFFDDE8C1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: Color(0xFFDDE8C1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: AppColor.primary),
                    ),
                  ),
                ),
                SizedBox(height: 22.h),
                Text(
                  appText.surahsTitle,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                for (var index = 0; index < surahs.length; index++) ...[
                  _SurahTile(
                    number: index + 1,
                    surah: surahs[index],
                    ayahWord: appText.ayahWord,
                  ),
                  SizedBox(height: 9.h),
                ],
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: HomeBottomNav(selectedIndex: 1),
          ),
        ],
      ),
    );
  }
}

class _Surah {
  const _Surah(this.name, this.meaning, this.ayahCount);

  final String name;
  final String meaning;
  final int ayahCount;
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({
    required this.number,
    required this.surah,
    required this.ayahWord,
  });

  final int number;
  final _Surah surah;
  final String ayahWord;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFDDE8C1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17.r,
            backgroundColor: const Color(0xFFDFE9B9),
            child: Text(
              '$number',
              style: TextStyle(color: AppColor.primary, fontSize: 12.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(surah.name, style: TextStyle(fontSize: 15.sp)),
                SizedBox(height: 3.h),
                Text(
                  surah.meaning,
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          Text(
            '${surah.ayahCount} $ayahWord',
            style: TextStyle(color: AppColor.primary, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
