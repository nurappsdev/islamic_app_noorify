import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

class HomeProgressSection extends StatelessWidget {
  const HomeProgressSection({super.key});

  static const _items = [
    _ProgressItem('Fardh Prayer', '0/7', .72),
    _ProgressItem('Sunnah and Witr', '0/6', .78),
    _ProgressItem('Quran', '0/11', .62),
    _ProgressItem('Nafl Salat', '0/2.5', .70),
    _ProgressItem('Hadith', '0/8', .64),
    _ProgressItem('Quiz', '0/2.5', .76),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 90.h,
            crossAxisSpacing: 11.w,
            mainAxisSpacing: 8.h,
          ),
          itemBuilder: (context, index) => _ProgressCard(item: _items[index]),
        ),
        SizedBox(height: 8.h),
        HomeCard(
          padding: EdgeInsets.symmetric(vertical: 13.h),
          child: Column(
            children: [
              Text('Nafl & more', style: homeSerifStyle(fontSize: 12.sp)),
              SizedBox(height: 6.h),
              const _ProgressBar(value: .58),
              SizedBox(height: 7.h),
              Text('0/3', style: homeSansStyle(fontSize: 12.sp)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressItem {
  const _ProgressItem(this.title, this.count, this.progress);

  final String title;
  final String count;
  final double progress;
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.item});

  final _ProgressItem item;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.symmetric(vertical: 9.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(item.title, style: homeSerifStyle(fontSize: 12.sp)),
          ),
          SizedBox(height: 7.h),
          _ProgressBar(value: item.progress),
          SizedBox(height: 6.h),
          Text(item.count, style: homeSansStyle(fontSize: 12.sp)),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64.w,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: LinearProgressIndicator(
          minHeight: 4.h,
          value: value,
          backgroundColor: const Color(0xFFE0E0E0),
          valueColor: const AlwaysStoppedAnimation(Color(0xFF88936B)),
        ),
      ),
    );
  }
}
