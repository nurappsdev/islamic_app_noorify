import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_tracking_screen.dart';
import 'package:islami_app_noorify/features/home/domain/entities/pillar_card.dart';
import 'package:islami_app_noorify/features/home/presentation/bloc/home_dashboard/home_dashboard_bloc.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

/// Server `pillarKey` -> the (English) title key [AppText.categoryLabel]
/// already knows how to localize. `nafl_and_more` isn't here: it drives the
/// full-width card below the grid instead of a grid tile.
const _pillarTitleKeyByKey = {
  'fardh_prayer': 'Fardh Prayer',
  'sunnah_witr': 'Sunnah and Witr',
  'quran': 'Quran',
  'zikr': 'Zikr',
  'hadith': 'Hadith',
  'quiz': 'Quiz',
};

const _naflAndMorePillarKey = 'nafl_and_more';

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
    final appText = AppText.of(context);
    final dashboardState = context.watch<HomeDashboardBloc>().state;
    final pillars = dashboardState.hasData
        ? dashboardState.dashboard!.pillarCards
        : null;

    final gridPillars = pillars
        ?.where((p) => p.pillarKey != _naflAndMorePillarKey)
        .toList();
    PillarCard? naflPillar;
    if (pillars != null) {
      for (final p in pillars) {
        if (p.pillarKey == _naflAndMorePillarKey) {
          naflPillar = p;
          break;
        }
      }
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: gridPillars?.length ?? _items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 90.h,
            crossAxisSpacing: 11.w,
            mainAxisSpacing: 8.h,
          ),
          itemBuilder: (context, index) => gridPillars != null
              ? _PillarProgressCard(pillar: gridPillars[index])
              : _ProgressCard(item: _items[index]),
        ),
        SizedBox(height: 8.h),
        InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => _openAmolTracking(context, 'Nafl & more'),
          child: HomeCard(
            padding: EdgeInsets.symmetric(vertical: 13.h),
            child: Column(
              children: [
                Text(
                  appText.categoryNaflAndMore,
                  style: homeSerifStyle(fontSize: 12.sp),
                ),
                SizedBox(height: 6.h),
                _ProgressBar(
                  value: naflPillar == null
                      ? .58
                      : (naflPillar.percentage / 100).clamp(0, 1).toDouble(),
                ),
                SizedBox(height: 7.h),
                Text(
                  naflPillar?.formattedSubtext ?? '0/3',
                  style: homeSansStyle(fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PillarProgressCard extends StatelessWidget {
  const _PillarProgressCard({required this.pillar});

  final PillarCard pillar;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final titleKey = _pillarTitleKeyByKey[pillar.pillarKey] ?? pillar.title;
    final progress = (pillar.percentage / 100).clamp(0, 1).toDouble();
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => _openAmolTracking(context, titleKey),
      child: HomeCard(
        padding: EdgeInsets.symmetric(vertical: 9.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                appText.categoryLabel(titleKey),
                style: homeSerifStyle(fontSize: 12.sp),
              ),
            ),
            SizedBox(height: 7.h),
            _ProgressBar(value: progress),
            SizedBox(height: 6.h),
            Text(pillar.formattedSubtext, style: homeSansStyle(fontSize: 12.sp)),
          ],
        ),
      ),
    );
  }
}

void _openAmolTracking(BuildContext context, String category) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AmolTrackingScreen(initialExpandedCategory: category),
    ),
  );
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
    final appText = AppText.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => _openAmolTracking(context, item.title),
      child: HomeCard(
        padding: EdgeInsets.symmetric(vertical: 9.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                appText.categoryLabel(item.title),
                style: homeSerifStyle(fontSize: 12.sp),
              ),
            ),
            SizedBox(height: 7.h),
            _ProgressBar(value: item.progress),
            SizedBox(height: 6.h),
            Text(item.count, style: homeSansStyle(fontSize: 12.sp)),
          ],
        ),
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
