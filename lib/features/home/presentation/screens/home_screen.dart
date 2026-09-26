import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/theme/app_palette.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/features/home/data/datasources/home_remote_data_source.dart';
import 'package:islami_app_noorify/features/home/data/repositories/home_repository_impl.dart';
import 'package:islami_app_noorify/features/home/domain/usecases/get_home_dashboard.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';
import 'package:islami_app_noorify/features/home/domain/current_prayer.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/entities/pillar_card.dart';
import 'package:islami_app_noorify/features/home/presentation/bloc/home_dashboard/home_dashboard_bloc.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/amal_tracker_card.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/amal_tracker_card_content.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_feature_grid.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_header.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_progress_section.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/prayer_time_card.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/prohibited_prayer_times_card.dart';
import 'package:islami_app_noorify/features/profile/data/services/profile_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeDashboardBloc>(
      create: (_) => HomeDashboardBloc(
        GetHomeDashboard(HomeRepositoryImpl(HomeRemoteDataSourceImpl())),
      )..add(const LoadHomeDashboard()),
      child: const _HomeScreenView(),
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

  Future<void> _onRefresh() async {
    final dashboardBloc = context.read<HomeDashboardBloc>();
    // Subscribe before dispatching so the loading -> done transition can't
    // be missed.
    final dashboardDone = dashboardBloc.stream.firstWhere(
      (state) => state.status != HomeDashboardStatus.loading,
    );
    dashboardBloc.add(const LoadHomeDashboard());

    try {
      await Future.wait([dashboardDone, ProfileService.instance.refresh()]);
    } catch (_) {
      // A bloc/stream teardown mid-refresh (e.g. navigating away) shouldn't
      // surface as an error from the pull-to-refresh gesture.
    }
    if (!mounted) return;
    setState(() => _refreshTick++);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status-bar icons on the dark background.
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: context.appPalette.background,
        body: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppColor.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(9.w, 6.h, 9.w, 92.h),
                  child: Column(
                    children: [
                      const HomeHeader(),
                      SizedBox(height: 10.h),
                      const AmalTrackerCard(),

                      SizedBox(height: 16.h),
                      KeyedSubtree(
                        key: ValueKey('prayer-time-card-$_refreshTick'),
                        child: const PrayerTimeCard(),
                      ),
                      SizedBox(height: 24.h),
                      KeyedSubtree(
                        key: ValueKey('prohibited-prayer-times-$_refreshTick'),
                        child: const ProhibitedPrayerTimesCard(),
                      ),
                      SizedBox(height: 16.h),
                      const _FardhPrayerCard(),
                      SizedBox(height: 14.h),
                      const HomeProgressSection(),
                      SizedBox(height: 10.h),
                      const HomeFeatureGrid(),
                    ],
                  ),
                ),
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: HomeBottomNav(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fardh-prayer card: [AmalTrackerCardContent] over [HomeGradientShape],
/// fed from the home dashboard when it has loaded. The bar of the prayer whose
/// period is running now is highlighted, using the same Aladhan times (and
/// on-device cache) as [PrayerTimeCard].
class _FardhPrayerCard extends StatefulWidget {
  const _FardhPrayerCard();

  @override
  State<_FardhPrayerCard> createState() => _FardhPrayerCardState();
}

class _FardhPrayerCardState extends State<_FardhPrayerCard> {
  DailyPrayerTimes? _times;
  Timer? _clockTimer;
  DateTime _now = bangladeshNow();

  @override
  void initState() {
    super.initState();
    _loadTimes();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _now = bangladeshNow());
      // Times may only reach the cache after PrayerTimeCard's fetch lands, or
      // roll over at midnight; re-reading the cache costs no network call.
      _refreshFromCache();
    });
  }

  Future<void> _refreshFromCache() async {
    try {
      final service = await AladhanPrayerTimeService.create();
      final cached = service.cachedPrayerTimes(_now);
      if (mounted && cached != null) setState(() => _times = cached);
    } catch (_) {}
  }

  Future<void> _loadTimes() async {
    try {
      final service = await AladhanPrayerTimeService.create();
      final cached = service.cachedPrayerTimes(_now);
      if (cached != null) {
        if (mounted) setState(() => _times = cached);
        return;
      }
      final fresh = await service.loadPrayerTimes(_now);
      if (mounted && fresh != null) setState(() => _times = fresh);
    } catch (_) {}
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeDashboardBloc>().state;
    final dashboard = state.hasData ? state.dashboard : null;
    PillarCard? fardh;
    for (final p in dashboard?.pillarCards ?? const <PillarCard>[]) {
      if (p.pillarKey == 'fardh_prayer') fardh = p;
    }

    final times = _times;
    final active = times == null ? null : currentPrayerPeriod(_now, times);
    final prayers = [
      for (final (i, prayer) in PrayerBarData.defaults.indexed)
        PrayerBarData(
          name: prayer.name,
          points: prayer.points,
          completed: prayer.completed,
          isActive: active != null && PrayerPeriod.values[i] == active,
        ),
    ];

    return HomeGradientShape(
      child: AmalTrackerCardContent(
        percentage: dashboard?.userSummary.percentageToday ?? 0,
        completedLabel: fardh?.formattedSubtext,
        prayers: prayers,
      ),
    );
  }
}

/// Rounded panel with a top-to-bottom white -> light green gradient.
class HomeGradientShape extends StatelessWidget {
  const HomeGradientShape({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24.r);
    return Container(
      width: double.infinity,
      height: 380.h,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFDCEBBB)],
        ),
        border: Border.all(color: const Color(0xFFDCEBBB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 60.h,
              child: Image.asset(
                'assets/newShape.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
            if (child != null) Positioned.fill(child: child!),
          ],
        ),
      ),
    );
  }
}

class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.backgroundColor,
    this.radius = 11,
    this.shadows,
  });

  final double radius;
  final List<BoxShadow>? shadows;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.surfaceColor(backgroundColor ?? palette.surface),
        borderRadius: BorderRadius.circular(radius.r),
        border: Border.all(
          color: context.lineColor(borderColor ?? palette.border),
        ),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}

/// Pass [context] to follow the active theme; without it (and without
/// [color]) the light-mode color is used.
TextStyle homeSerifStyle({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  BuildContext? context,
}) {
  return TextStyle(
    color: color ?? (context?.appPalette ?? AppPalette.light).textStrong,
    fontSize: fontSize,
    fontFamily: 'Times New Roman',
    fontStyle: FontStyle.italic,
    fontWeight: fontWeight,
  );
}

TextStyle homeSansStyle({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  BuildContext? context,
}) {
  return TextStyle(
    color: color ?? (context?.appPalette ?? AppPalette.light).textPrimary,
    fontSize: fontSize,
    fontWeight: fontWeight,
  );
}

class HomeCircleButton extends StatelessWidget {
  const HomeCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size ?? 25.r,
      child: IconButton(
        onPressed: onPressed ?? () {},
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: context.appPalette.tint,
          foregroundColor: AppColor.primary,
        ),
        icon: Icon(icon, size: 15.sp),
      ),
    );
  }
}
