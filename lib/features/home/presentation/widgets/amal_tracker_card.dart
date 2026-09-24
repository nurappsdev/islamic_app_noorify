import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/theme/app_palette.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_tracking_screen.dart';
import 'package:islami_app_noorify/features/home/domain/entities/highlight_card.dart';
import 'package:islami_app_noorify/features/home/presentation/bloc/home_dashboard/home_dashboard_bloc.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_shimmer.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/widgets/amol_progress_ring.dart';

class AmalTrackerCard extends StatefulWidget {
  const AmalTrackerCard({super.key});

  @override
  State<AmalTrackerCard> createState() => _AmalTrackerCardState();
}

class _AmalTrackerCardState extends State<AmalTrackerCard> {
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
      case 'todays_highest':
      case 'todays_second_highest':
      case 'yesterdays_highest':
        return _AmalTrackerItem(
          title: card.title,
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
          subtitle: '${appText.secondInTheMonth}\n${appText.point} : $fraction',
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
          title: card.title,
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

  static const _slideDuration = Duration(seconds: 3);
  static const _transitionDuration = Duration(milliseconds: 650);

  // The PageView is endless (item = page % length) so the last card glides
  // forward into the first one instead of rewinding through every card. It
  // starts far from 0 so the user can also swipe backwards from the first
  // card. 5040 (= 7!) divides evenly by every plausible card count, so the
  // first page always shows card 0 whether the API or fallback list is used.
  static const _initialPage = 5040 * 100;

  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = _initialPage;
  bool _isHolding = false;
  bool _isAutoSliding = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: .98,
      initialPage: _initialPage,
    );
    _scheduleAutoSlide();
  }

  /// True while the slider is actually in front of the user: not scrolled
  /// out of the viewport and not hidden behind another route.
  bool get _isOnScreen {
    if (!TickerMode.valuesOf(context).enabled) return false;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    return bottom > 0 && top < MediaQuery.sizeOf(context).height;
  }

  /// Waits [_slideDuration] with the current slide fully at rest, then
  /// glides to the next one and reschedules itself — so every slide gets
  /// the same 3-second dwell time regardless of the transition length.
  /// The advance is skipped (and retried a dwell later) while the user is
  /// holding the slider or has scrolled it out of view, so it stays on the
  /// same card until they come back.
  void _scheduleAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer(_slideDuration, () async {
      if (!mounted) return;
      if (_isHolding || !_isOnScreen || !_pageController.hasClients) {
        _scheduleAutoSlide();
        return;
      }
      _isAutoSliding = true;
      await _pageController.nextPage(
        duration: _transitionDuration,
        curve: Curves.easeInOutCubic,
      );
      _isAutoSliding = false;
      if (!mounted) return;
      _scheduleAutoSlide();
    });
  }

  void _onPointerDown(PointerDownEvent _) {
    _isHolding = true;
    // Pressing during a glide settles on the nearest card instead of letting
    // the slide carry on under the finger.
    if (_isAutoSliding && _pageController.hasClients) {
      final page = _pageController.page;
      if (page != null) {
        _pageController.animateToPage(
          page.round(),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _onPointerEnd(PointerEvent _) {
    _isHolding = false;
    // Fresh dwell for whichever card the user let go on.
    _scheduleAutoSlide();
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
    if (dashboardState.isLoading) return const AmalTrackerCardShimmer();

    final items = dashboardState.hasData
        ? _apiItems(appText, dashboardState.dashboard!.topHighlightCards)
        : _items(appText);
    if (items.isEmpty) return const SizedBox.shrink();
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        SizedBox(
          height: 108.h,
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerEnd,
            onPointerCancel: _onPointerEnd,
            child: PageView.builder(
              // Lets the controller restore the page if the slider is rebuilt
              // from scratch (e.g. the shimmer shows during a refresh).
              key: const PageStorageKey<String>('amal-tracker-slider'),
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                _currentPage = index;
                // A manual swipe shouldn't get cut short by an auto-advance
                // landing right after it, so give this slide a fresh 3s dwell.
                _scheduleAutoSlide();
              },
              itemBuilder: (context, pageIndex) {
                final index = pageIndex % items.length;
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    var page = _currentPage.toDouble();
                    if (_pageController.hasClients &&
                        _pageController.position.haveDimensions) {
                      page = _pageController.page ?? page;
                    }
                    final delta = (page - pageIndex).abs().clamp(0.0, 1.0);
                    final scale = 1 - (delta * 0.08);
                    final opacity = 1 - (delta * 0.35);
                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(scale: scale, child: child),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: _AmalSlide(
                      item: items[index],
                      isTodaysTrack: index == 0,
                    ),
                  ),
                );
              },
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
      backgroundColor: context.appPalette.tint,
      borderColor: context.appPalette.tint,
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
                  style: homeSansStyle(context: context, fontSize: 13.sp),
                ),
                SizedBox(height: 5.h),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: homeSansStyle(
                    context: context,
                    fontSize: 9.sp,
                  ).copyWith(height: 1.3),
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
            holeColor: context.appPalette.tint,
            labelStyle: homeSansStyle(
              context: context,
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
        color: context.appPalette.tintSoft,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: item.leadingText == null
          ? Image.asset(
              'assets/noorifyLogo.png',
              fit: BoxFit.contain,
              color: context.inkColor(Color(0xFF879461)),
            )
          : Text(
              item.leadingText!,
              style: homeSansStyle(
                context: context,
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
