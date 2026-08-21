import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/home/presentation/screens/amol_tracking_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/amol_progress_ring.dart';

class AmalTrackerCard extends StatefulWidget {
  const AmalTrackerCard({super.key});

  @override
  State<AmalTrackerCard> createState() => _AmalTrackerCardState();
}

class _AmalTrackerCardState extends State<AmalTrackerCard> {
  static const _items = [
    _AmalTrackerItem(
      title: 'Todays Amol track',
      subtitle: 'Point : 30/40',
      progressLabel: '86 %',
      progress: .86,
    ),
    _AmalTrackerItem(
      title: 'Todays highest value',
      subtitle: 'Point : 30.5/40',
      progressLabel: '86.9 %',
      progress: .869,
    ),
    _AmalTrackerItem(
      title: 'Todays 2nd highest',
      subtitle: 'Point : 30.5/40',
      progressLabel: '86.9 %',
      progress: .869,
    ),
    _AmalTrackerItem(
      title: 'Yesterdays highest',
      subtitle: 'Point : 30.5/40',
      progressLabel: '86.9 %',
      progress: .869,
    ),
    _AmalTrackerItem(
      title: 'Abdullah Al-aziz',
      subtitle: '1st In The Month\nPoint : 432/560',
      progressLabel: '86.9 %',
      progress: .869,
    ),
    _AmalTrackerItem(
      title: 'Khalid Saifullah',
      subtitle: '2nd In The Month\nPoint : 421/560',
      progressLabel: '86.9 %',
      progress: .869,
    ),
    _AmalTrackerItem(
      title: 'Abdullah Al-aziz',
      subtitle: 'Last Month Winner\nPoint : 930/1240',
      progressLabel: '86.9 %',
      progress: .869,
    ),
    _AmalTrackerItem(
      title: 'My position in, July',
      subtitle: 'Point : 30.5/40',
      progressLabel: '63 %',
      progress: .63,
      leadingText: '13',
    ),
  ];

  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: .98);
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _currentPage = (_currentPage + 1) % _items.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        SizedBox(
          height: 108.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            onPageChanged: (index) => _currentPage = index,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: _AmalSlide(item: _items[index], isTodaysTrack: index == 0),
              );
            },
          ),
        ),
        Positioned(
          bottom: -23.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFAAB85D),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(6.r)),
            ),
            child: Text(
              'Sehri : 4:09 AM     Iftar : 6:33 PM',
              style: homeSansStyle(fontSize: 9.sp, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AmalSlide extends StatelessWidget {
  const _AmalSlide({required this.item, required this.isTodaysTrack});

  final _AmalTrackerItem item;
  final bool isTodaysTrack;

  @override
  Widget build(BuildContext context) {
    final card = HomeCard(
      padding: EdgeInsets.fromLTRB(9.w, 9.h, 9.w, 9.h),
      backgroundColor: const Color(0xFFDDE8AE),
      borderColor: const Color(0xFFDDE8AE),
      child: Row(
        children: [
          _LeadingIcon(item: item),
          SizedBox(width: 7.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: homeSansStyle(fontSize: 13.sp),
                ),
                SizedBox(height: 5.h),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: homeSansStyle(fontSize: 9.sp).copyWith(height: 1.3),
                ),
              ],
            ),
          ),
          SizedBox(width: 4.w),
          AmolProgressRing(
            label: item.progressLabel,
            progress: item.progress,
            dimension: 84.r,
            holeDimension: 57.r,
            labelStyle: homeSansStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    if (!isTodaysTrack) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AmolTrackingScreen(
            pointLabel: item.subtitle,
            progressLabel: item.progressLabel,
            progress: item.progress,
          ),
        ),
      ),
      child: card,
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.item});

  final _AmalTrackerItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.r,
      height: 52.r,
      padding: EdgeInsets.all(item.leadingText == null ? 12.r : 0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8E8),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: item.leadingText == null
          ? Image.asset(
              'assets/noorifyLogo.png',
              fit: BoxFit.contain,
              color: const Color(0xFF879461),
            )
          : Text(
              item.leadingText!,
              style: homeSansStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _AmalTrackerItem {
  const _AmalTrackerItem({
    required this.title,
    required this.subtitle,
    required this.progressLabel,
    required this.progress,
    this.leadingText,
  });

  final String title;
  final String subtitle;
  final String progressLabel;
  final double progress;
  final String? leadingText;
}
