import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_tracking_screen.dart';
import 'package:islami_app_noorify/features/home/domain/entities/highlight_card.dart';
import 'package:islami_app_noorify/features/home/presentation/bloc/home_dashboard/home_dashboard_bloc.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/widgets/amol_progress_ring.dart';

class AmalTrackerCard extends StatefulWidget {
  const AmalTrackerCard({super.key});

  @override
  State<AmalTrackerCard> createState() => _AmalTrackerCardState();
}

class _AmalTrackerCardState extends State<AmalTrackerCard> {
  // Updated on every build to match whichever item list (API or static
  // fallback) is on screen, so the auto-slide timer wraps correctly.
  int _itemCount = 8;

  static List<_AmalTrackerItem> _items(AppText appText) => [
    _AmalTrackerItem(
      title: appText.todaysAmolTrack,
      subtitle: '${appText.point} : 30/40',
      progressLabel: '86 %',
      progress: .86,
    ),
    _AmalTrackerItem(
      title: appText.todaysHighestValue,
      subtitle: '${appText.point} : 30.5/40',
      progressLabel: '86.9 %',
      progress: .869,
    ),
    _AmalTrackerItem(
      title: appText.todays2ndHighest,
      subtitle: '${appText.point} : 30.5/40',
      progressLabel: '86.9 %',
      progress: .869,
    ),
    _AmalTrackerItem(
      title: appText.yesterdaysHighest,
      subtitle: '${appText.point} : 30.5/40',
      progressLabel: '86.9 %',
      progress: .869,
    ),
    _AmalTrackerItem(
      title: appText.competitorName,
      subtitle: '${appText.firstInTheMonth}\n${appText.point} : 432/560',
      progressLabel: '86.9 %',
      progress: .869,
    ),
    _AmalTrackerItem(
      title: appText.khalidSaifullah,
      subtitle: '${appText.secondInTheMonth}\n${appText.point} : 421/560',
      progressLabel: '86.9 %',
      progress: .869,
    ),
    _AmalTrackerItem(
      title: appText.competitorName,
      subtitle: '${appText.lastMonthWinner}\n${appText.point} : 930/1240',
      progressLabel: '86.9 %',
      progress: .869,
    ),
    _AmalTrackerItem(
      title: appText.myPositionInMonth,
      subtitle: '${appText.point} : 30.5/40',
      progressLabel: '63 %',
      progress: .63,
      leadingText: '13',
    ),
  ];

  /// Builds the carousel items from `GET /home/dashboard`'s
  /// `topHighlightCards`, keeping the app's own localized labels and only
  /// pulling the dynamic bits (points, percentage, names, rank) from the API.
  static List<_AmalTrackerItem> _apiItems(
    AppText appText,
    List<HighlightCard> cards,
  ) => cards.map((card) => _mapHighlightCard(appText, card)).toList();

  static _AmalTrackerItem _mapHighlightCard(
    AppText appText,
    HighlightCard card,
  ) {
    final fraction = _fractionOf(card.pointsText);
    final progress = (card.percentage / 100).clamp(0, 1).toDouble();
    final progressLabel = _formatPercentage(card.percentage);

    switch (card.type) {
      case 'todays_amol':
        return _AmalTrackerItem(
          title: appText.todaysAmolTrack,
          subtitle: '${appText.point} : $fraction',
          progressLabel: progressLabel,
          progress: progress,
        );
      case 'todays_highest':
        return _AmalTrackerItem(
          title: appText.todaysHighestValue,
          subtitle: '${appText.point} : $fraction',
          progressLabel: progressLabel,
          progress: progress,
        );
      case 'todays_second_highest':
        return _AmalTrackerItem(
          title: appText.todays2ndHighest,
          subtitle: '${appText.point} : $fraction',
          progressLabel: progressLabel,
          progress: progress,
        );
      case 'yesterdays_highest':
        return _AmalTrackerItem(
          title: appText.yesterdaysHighest,
          subtitle: '${appText.point} : $fraction',
          progressLabel: progressLabel,
          progress: progress,
        );
      case 'monthly_first':
        return _AmalTrackerItem(
          title: card.userName ?? appText.competitorName,
          subtitle: '${appText.firstInTheMonth}\n${appText.point} : $fraction',
          progressLabel: progressLabel,
          progress: progress,
        );
      case 'monthly_second':
        return _AmalTrackerItem(
          title: card.userName ?? appText.khalidSaifullah,
          subtitle:
              '${appText.secondInTheMonth}\n${appText.point} : $fraction',
          progressLabel: progressLabel,
          progress: progress,
        );
      case 'last_month_winner':
        return _AmalTrackerItem(
          title: card.userName ?? appText.competitorName,
          subtitle: '${appText.lastMonthWinner}\n${appText.point} : $fraction',
          progressLabel: progressLabel,
          progress: progress,
        );
      case 'my_monthly_position':
        return _AmalTrackerItem(
          title: appText.myPositionInMonth,
          subtitle: '${appText.point} : $fraction',
          progressLabel: progressLabel,
          progress: progress,
          leadingText: card.rank?.toString(),
        );
      default:
        // Unknown card type from a newer backend: fall back to whatever the
        // API itself sent instead of dropping the card.
        return _AmalTrackerItem(
          title: card.title,
          subtitle: fraction.isEmpty ? (card.subtitle ?? '') : fraction,
          progressLabel: progressLabel,
          progress: progress,
        );
    }
  }

  /// `"Point : 0/40"` -> `"0/40"`.
  static String _fractionOf(String? pointsText) {
    if (pointsText == null) return '';
    final index = pointsText.indexOf(':');
    return (index == -1 ? pointsText : pointsText.substring(index + 1)).trim();
  }

  static String _formatPercentage(num percentage) {
    final isWhole = percentage % 1 == 0;
    return '${percentage.toStringAsFixed(isWhole ? 0 : 1)} %';
  }

  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: .98);
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients || _itemCount == 0) return;
      _currentPage = (_currentPage + 1) % _itemCount;
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
    final appText = AppText.of(context);
    final dashboardState = context.watch<HomeDashboardBloc>().state;
    final items = dashboardState.hasData
        ? _apiItems(appText, dashboardState.dashboard!.topHighlightCards)
        : _items(appText);
    _itemCount = items.length;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        SizedBox(
          height: 108.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: items.length,
            onPageChanged: (index) => _currentPage = index,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: _AmalSlide(
                  item: items[index],
                  isTodaysTrack: index == 0,
                ),
              );
            },
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
            labelStyle: homeSansStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
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
