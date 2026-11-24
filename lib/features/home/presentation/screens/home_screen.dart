// Home, split by platform so it is obvious which code serves which build.
//
// This file is the single entry point and holds only what BOTH platforms use:
// `HomeScreen`, the shared screen state (day rollover, refresh, exit
// confirmation) and the one `kIsWeb` switch that picks a dashboard.
//
//   home_screen.dart               <- you are here: entry + shared state
//   home_screen_mobile.dart        <- ANDROID / iOS ONLY
//   home_screen_web.dart           <- WEB ONLY  (dashboard layout)
//   home_screen_web_chrome.dart    <- WEB ONLY  (top bar, sidebar, footer)
//   home_screen_shared_cards.dart  <- SHARED    (the cards both layouts use)
//
// The platform fork is in `build` below: `kIsWeb` chooses
// `_WebHomeDashboard` or `_MobileHomeDashboard`. Nothing else in Home
// branches on the platform. The four files above are `part`s of this library,
// so they need no imports of their own - every import lives here.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/localization/localized_date_formatter.dart';
import 'package:tuhfatul_muslim/features/promo_banner/presentation/widgets/promo_banner_carousel.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pillar.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/state/amol_daily_store.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/state/amol_day_clock.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_entry_label.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/update/app_update_watcher.dart';
import 'package:tuhfatul_muslim/core/theme/app_palette.dart';
import 'package:tuhfatul_muslim/core/theme/app_typography.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/screens/amol_tracking_screen.dart';
import 'package:tuhfatul_muslim/features/home/data/datasources/home_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/home/data/repositories/home_repository_impl.dart';
import 'package:tuhfatul_muslim/features/home/domain/usecases/get_home_dashboard.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_time_service.dart';
import 'package:tuhfatul_muslim/features/home/domain/current_prayer.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/entities/pillar_card.dart';
import 'package:tuhfatul_muslim/features/home/presentation/bloc/home_dashboard/home_dashboard_bloc.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/amal_tracker_card.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/amal_tracker_card_content.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/hadith_reading_card_content.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/home_feature_card_slider.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/quiz_card_content.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/quran_card_content.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/zikr_localized_name.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/home_feature_grid.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/home_header.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/nafl_more_card_content.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/prayer_time_card.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/prayer_location_widgets.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/sunnah_witr_card_content.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/zikr_card_content.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/prohibited_prayer_times_card.dart';
import 'package:tuhfatul_muslim/features/notifications/data/services/notification_badge_service.dart';
import 'package:tuhfatul_muslim/features/profile/data/services/profile_service.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';
import 'package:tuhfatul_muslim/shared/widgets/profile_avatar_circle.dart';

import '../widgets/home_progress_section.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/navigation/amol_tracker_navigation.dart';

part 'home_screen_mobile.dart';
part 'home_screen_shared_cards.dart';
part 'home_screen_web.dart';
part 'home_screen_web_chrome.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrayerLocationScope(
      child: BlocProvider<HomeDashboardBloc>(
        create: (_) => HomeDashboardBloc(
          GetHomeDashboard(HomeRepositoryImpl(HomeRemoteDataSourceImpl())),
        )..add(const LoadHomeDashboard()),
        // Home is the first screen of every launch, so the Google Play
        // update check runs from here.
        child: const AppUpdateWatcher(child: _HomeScreenView()),
      ),
    );
  }
}

class _HomeScreenView extends StatefulWidget {
  const _HomeScreenView();

  @override
  State<_HomeScreenView> createState() => _HomeScreenViewState();
}

class _HomeScreenViewState extends State<_HomeScreenView> {
  // Bumped on every pull-to-refresh to remount the prayer-time cards below,
  // which fetch their own data independently of HomeDashboardBloc.
  int _refreshTick = 0;

  // The percentages on the cards come from the home dashboard, while the
  // tracker only refreshes AmolDailyStore when the user ticks something and
  // leaves. Refetch the dashboard whenever the store changes so the cards
  // update as soon as the user is back.
  bool _storeLoadedOnce = false;

  /// Prevents the store's refresh notification from scheduling a second Home
  /// dashboard request while a pull-to-refresh request is already in flight.
  bool _isPullRefreshing = false;

  /// Avoid opening more than one confirmation dialog if back is invoked again
  /// before the current dialog has been dismissed.
  bool _isExitDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _storeLoadedOnce = AmolDailyStore.instance.value != null;
    AmolDailyStore.instance.addListener(_onAmolStoreChanged);
    AmolDayClock.instance.addListener(_onDayChanged);
    unawaited(NotificationBadgeService.instance.refresh());
  }

  @override
  void dispose() {
    AmolDailyStore.instance.removeListener(_onAmolStoreChanged);
    AmolDayClock.instance.removeListener(_onDayChanged);
    super.dispose();
  }

  /// Midnight, with Home on screen: every daily figure here belongs to the
  /// day that has just ended. The dashboard is fetched again for the new day
  /// — and shows zero until it answers, rather than yesterday's totals (see
  /// [HomeDashboardBloc]) — while the prayer cards are rebuilt for the new
  /// date.
  void _onDayChanged() {
    if (!mounted) return;
    context.read<HomeDashboardBloc>().add(
      const LoadHomeDashboard(silent: true),
    );
    setState(() => _refreshTick++);
  }

  void _onAmolStoreChanged() {
    // The first load only fills the checklist; nothing has changed yet.
    if (!_storeLoadedOnce) {
      _storeLoadedOnce = true;
      return;
    }
    // A reset (sign-in/out clears it) isn't a tracking change to refetch for;
    // the fresh checklist that follows is.
    if (AmolDailyStore.instance.value == null) return;
    if (!mounted || _isPullRefreshing) return;
    context.read<HomeDashboardBloc>().add(
      const LoadHomeDashboard(silent: true),
    );
  }

  Future<void> _onRefresh() async {
    final dashboardBloc = context.read<HomeDashboardBloc>();
    _isPullRefreshing = true;
    // Subscribe before dispatching so the loading -> done transition can't
    // be missed.
    final dashboardDone = dashboardBloc.stream.firstWhere(
      (state) => state.status != HomeDashboardStatus.loading,
    );
    dashboardBloc.add(const LoadHomeDashboard());

    try {
      await Future.wait([
        dashboardDone,
        ProfileService.instance.refresh(),
        AmolDailyStore.instance.load(),
        NotificationBadgeService.instance.refresh(),
      ]);
    } catch (_) {
      // A bloc/stream teardown mid-refresh (e.g. navigating away) shouldn't
      // surface as an error from the pull-to-refresh gesture.
    } finally {
      _isPullRefreshing = false;
    }
    if (!mounted) return;
    setState(() => _refreshTick++);
  }

  Future<void> _confirmExit() async {
    if (_isExitDialogVisible || !mounted) return;
    _isExitDialogVisible = true;

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('অ্যাপ থেকে বের হতে চান?'),
        content: const Text('আপনি কি নিশ্চিত যে অ্যাপ থেকে বের হতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('হ্যাঁ'),
          ),
        ],
      ),
    );

    _isExitDialogVisible = false;
    if (shouldExit == true && mounted) {
      // This closes the app without affecting the signed-in session or any
      // locally stored user data.
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language = context.watch<LanguageBloc>().state.language;
    // The confirmation applies only when Home is the navigator's root. When
    // Home has been opened above another route, normal back navigation remains
    // available; internal pages are not wrapped by this PopScope.
    final isRootRoute = ModalRoute.of(context)?.isFirst ?? true;
    return PopScope(
      canPop: !isRootRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isRootRoute) _confirmExit();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // Light status-bar icons on the dark background.
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontFamily: appFontFamilyFor(language),
            fontFamilyFallback: appFontFamilyFallback,
          ),
          child: Scaffold(
            backgroundColor: context.appPalette.background,
            body: SafeArea(
              child: Column(
                children: [
                  // Fixed above the scroll view (not inside it), so it never
                  // scrolls away with the content below.
                  if (!kIsWeb)
                    Padding(
                      padding: EdgeInsets.fromLTRB(9.w, 6.h, 9.w, 0),
                      child: const HomeHeader(),
                    ),
                  Expanded(
                    child: kIsWeb
                        ? _WebHomeDashboard(
                            language: language,
                            refreshTick: _refreshTick,
                            onRefresh: _onRefresh,
                          )
                        : _MobileHomeDashboard(
                            language: language,
                            refreshTick: _refreshTick,
                            onRefresh: _onRefresh,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
