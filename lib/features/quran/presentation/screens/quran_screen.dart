import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_bottom_nav.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  static const _surahs = [
    ('Al-Fatihah', 'The Opening', '7 Ayahs'),
    ('Al-Baqarah', 'The Cow', '286 Ayahs'),
    ('Al-Imran', 'The Family of Imran', '200 Ayahs'),
    ('An-Nisa', 'The Women', '176 Ayahs'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 90.h),
              children: [
                Center(
                  child: Text(
                    'Quran',
                    style: TextStyle(color: AppColor.primary, fontSize: 20.sp),
                  ),
                ),
                SizedBox(height: 24.h),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search surah',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF2F6E7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Surahs',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                for (var index = 0; index < _surahs.length; index++)
                  _SurahTile(number: index + 1, data: _surahs[index]),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: HomeBottomNav(selectedIndex: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.number, required this.data});
  final int number;
  final (String, String, String) data;

  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(bottom: 9.h),
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F6E7),
      borderRadius: BorderRadius.circular(14.r),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 17.r,
          backgroundColor: const Color(0xFFDFE9B9),
          child: Text('$number', style: TextStyle(color: AppColor.primary)),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.$1, style: TextStyle(fontSize: 15.sp)),
              SizedBox(height: 3.h),
              Text(
                data.$2,
                style: TextStyle(color: Colors.grey, fontSize: 12.sp),
              ),
            ],
          ),
        ),
        Text(
          data.$3,
          style: TextStyle(color: AppColor.primary, fontSize: 12.sp),
        ),
      ],
    ),
  );
}
