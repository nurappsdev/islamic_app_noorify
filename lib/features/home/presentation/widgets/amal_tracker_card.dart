import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

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
                child: _AmalSlide(item: _items[index]),
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
  const _AmalSlide({required this.item});

  final _AmalTrackerItem item;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
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
          Container(
            width: 90.r,
            height: 90.r,
            alignment: Alignment.center,
            child: _ContainerProgressRing(
              label: item.progressLabel,
              progress: item.progress,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContainerProgressRing extends StatelessWidget {
  const _ContainerProgressRing({required this.label, required this.progress});

  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 84.r,
      child: CustomPaint(
        painter: _AmalProgressRingPainter(progress: progress),
        child: Center(
          child: Container(
            width: 57.r,
            height: 57.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFDDE8AE),
              shape: BoxShape.circle,
            ),
            child: Text(
              label,
              style: homeSansStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmalProgressRingPainter extends CustomPainter {
  const _AmalProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * .12;
    final ringRect =
        Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final clampedProgress = progress.clamp(0.0, 1.0);

    final trackPaint = Paint()
      ..color = const Color(0xFFF0EE74)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xFF879461)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(ringRect, 0, math.pi * 2, false, trackPaint);
    canvas.drawArc(
      ringRect,
      -math.pi / 2,
      math.pi * 2 * clampedProgress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AmalProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
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
