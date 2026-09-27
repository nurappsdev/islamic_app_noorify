import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_tracking_screen.dart';
import 'package:islami_app_noorify/features/home/domain/entities/highlight_card.dart';
import 'package:islami_app_noorify/features/home/presentation/bloc/home_dashboard/home_dashboard_bloc.dart';
import 'package:islami_app_noorify/features/home/presentation/utils/amol_track_card_utils.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_shimmer.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';
import 'package:islami_app_noorify/shared/services/app_globals.dart';
import 'package:islami_app_noorify/shared/widgets/amal_tracker_tile.dart';

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
  /// `topHighlightCards`, selecting the language-specific strings returned by
  /// the API and retaining the app's labels as compatibility fallbacks.
  static List<_AmalTrackerItem> _apiItems(
    BuildContext context,
    AppText appText,
    List<HighlightCard> cards,
    String loggedInUserName,
    String monthLabel,
  ) => [
    for (final card in cards)
      if (card.hasData)
        _mapHighlightCard(context, appText, card, loggedInUserName, monthLabel),
  ];

  static _AmalTrackerItem _mapHighlightCard(
    BuildContext context,
    AppText appText,
    HighlightCard card,
    String loggedInUserName,
    String monthLabel,
  ) {
    final title = truncateWords(
      _localized(context, card.localizedTitle, card.title),
      15,
    );
    final pointsText = _localized(
      context,
      card.localizedPointsText,
      card.pointsText,
    );
    final subtitle = _localized(context, card.localizedSubtitle, card.subtitle);
    final fraction = _fractionOf(pointsText);
    final progress = (card.percentage / 100).clamp(0, 1).toDouble();
    final localizedPercentage = context.localized(card.localizedPercentage);
    final progressLabel = localizedPercentage.isEmpty
        ? _formatPercentage(card.percentage)
        : '$localizedPercentage %';
    final userName = card.type == 'todays_amol'
        ? loggedInUserName
        : resolveAmolTrackUserName(
            profileName: card.userName,
            dashboardName: loggedInUserName,
          );

    switch (card.type) {
      case 'todays_amol':
      case 'todays_highest':
      case 'todays_second_highest':
      case 'yesterdays_highest':
        return _AmalTrackerItem(
          title: title,
          subtitle: pointsText.isEmpty
              ? '${appText.point} : $fraction'
              : pointsText,
          progressLabel: progressLabel,
          progress: progress,
          userName: userName,
          monthLabel: monthLabel,
        );
      case 'monthly_first':
        return _AmalTrackerItem(
          title: title,
          subtitle: subtitle.isEmpty
              ? '${appText.firstInTheMonth}\n${appText.point} : $fraction'
              : subtitle,
          progressLabel: progressLabel,
          progress: progress,
          userName: userName,
          monthLabel: monthLabel,
        );
      case 'monthly_second':
        return _AmalTrackerItem(
          title: title,
          subtitle: subtitle.isEmpty
              ? '${appText.secondInTheMonth}\n${appText.point} : $fraction'
              : subtitle,
          progressLabel: progressLabel,
          progress: progress,
          userName: userName,
          monthLabel: monthLabel,
        );
      case 'last_month_winner':
        return _AmalTrackerItem(
          title: title,
          subtitle: subtitle.isEmpty
              ? '${appText.lastMonthWinner}\n${appText.point} : $fraction'
              : subtitle,
          progressLabel: progressLabel,
          progress: progress,
          userName: userName,
          monthLabel: monthLabel,
        );
      case 'my_monthly_position':
        return _AmalTrackerItem(
          title: title,
          subtitle: pointsText.isEmpty
              ? '${appText.point} : $fraction'
              : pointsText,
          progressLabel: progressLabel,
          progress: progress,
          userName: userName,
          monthLabel: monthLabel,
          leadingText: _localized(
            context,
            card.localizedRank,
            card.rank?.toString(),
          ),
        );
      default:
        // Unknown card type from a newer backend: fall back to whatever the
        // API itself sent instead of dropping the card.
        return _AmalTrackerItem(
          title: title,
          subtitle: pointsText.isEmpty
              ? (subtitle.isEmpty ? fraction : subtitle)
              : pointsText,
          progressLabel: progressLabel,
          progress: progress,
          userName: userName,
          monthLabel: monthLabel,
        );
    }
  }

  static String _localized(
    BuildContext context,
    LocalizedText value,
    String? fallback,
  ) {
    final text = context.localized(value);
    return text.isEmpty ? (fallback ?? '') : text;
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

  static List<_AmalTrackerItem> _withDisplayInfo(
    List<_AmalTrackerItem> items,
    String userName,
    String monthLabel,
  ) => [
    for (final item in items)
      item.copyWith(
        title: truncateWords(item.title, 15),
        userName: userName,
        monthLabel: monthLabel,
      ),
  ];

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
    final language = context.watch<LanguageBloc>().state.language;
    if (dashboardState.isLoading) return const AmalTrackerCardShimmer();

    final dashboard = dashboardState.dashboard;
    final dashboardName = context.localized(
      dashboard?.userSummary.localizedFullName,
    );
    final fallbackDashboardName = dashboardName.isEmpty
        ? dashboard?.userSummary.fullName
        : dashboardName;
    final monthLabel = localizedShortMonthYear(
      dashboard?.dashboardDate ?? DateTime.now(),
      language,
    );

    return ValueListenableBuilder<String?>(
      valueListenable: profileNameNotifier,
      builder: (context, profileName, _) {
        final loggedInUserName = resolveAmolTrackUserName(
          profileName: profileName,
          dashboardName: fallbackDashboardName,
        );
        final items = dashboardState.hasData
            ? _apiItems(
                context,
                appText,
                dashboard!.topHighlightCards,
                loggedInUserName,
                monthLabel,
              )
            : _withDisplayInfo(_items(appText), loggedInUserName, monthLabel);
        if (items.isEmpty) return const SizedBox.shrink();
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            SizedBox(
              height: AmalTrackerTile.height,
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
      },
    );
  }
}

class _AmalSlide extends StatelessWidget {
  const _AmalSlide({required this.item, required this.isTodaysTrack});

  final _AmalTrackerItem item;
  final bool isTodaysTrack;

  @override
  Widget build(BuildContext context) {
    final card = AmalTrackerTile(
      title: item.title,
      subtitle: item.subtitle,
      userName: item.userName,
      monthLabel: item.monthLabel,
      progressLabel: item.progressLabel,
      progress: item.progress,
      leadingText: item.leadingText,
    );

    if (!isTodaysTrack) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(AmalTrackerTile.radius),
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

class _AmalTrackerItem {
  const _AmalTrackerItem({
    required this.title,
    required this.subtitle,
    required this.progressLabel,
    required this.progress,
    this.leadingText,
    this.userName,
    this.monthLabel,
  });

  final String title;
  final String subtitle;
  final String progressLabel;
  final double progress;
  final String? leadingText;
  final String? userName;
  final String? monthLabel;

  _AmalTrackerItem copyWith({
    String? title,
    String? userName,
    String? monthLabel,
  }) {
    return _AmalTrackerItem(
      title: title ?? this.title,
      subtitle: subtitle,
      progressLabel: progressLabel,
      progress: progress,
      leadingText: leadingText,
      userName: userName ?? this.userName,
      monthLabel: monthLabel ?? this.monthLabel,
    );
  }
}
