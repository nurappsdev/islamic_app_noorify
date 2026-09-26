import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_item.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/state/amol_daily_store.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/theme/app_palette.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_tracking_screen.dart';
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
import 'package:islami_app_noorify/features/home/presentation/widgets/hadith_reading_card_content.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_feature_card_slider.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/quiz_card_content.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/quran_card_content.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_feature_grid.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_header.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_progress_section.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/nafl_more_card_content.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/prayer_time_card.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/sunnah_witr_card_content.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/zikr_card_content.dart';
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

  // The percentages on the cards come from the home dashboard, while the
  // tracker only refreshes AmolDailyStore when the user ticks something and
  // leaves. Refetch the dashboard whenever the store changes so the cards
  // update as soon as the user is back.
  bool _storeLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _storeLoadedOnce = AmolDailyStore.instance.value != null;
    AmolDailyStore.instance.addListener(_onAmolStoreChanged);
  }

  @override
  void dispose() {
    AmolDailyStore.instance.removeListener(_onAmolStoreChanged);
    super.dispose();
  }

  void _onAmolStoreChanged() {
    // The first load only fills the checklist; nothing has changed yet.
    if (!_storeLoadedOnce) {
      _storeLoadedOnce = true;
      return;
    }
    if (!mounted) return;
    context.read<HomeDashboardBloc>().add(
      const LoadHomeDashboard(silent: true),
    );
  }

  Future<void> _onRefresh() async {
    final dashboardBloc = context.read<HomeDashboardBloc>();
    // Subscribe before dispatching so the loading -> done transition can't
    // be missed.
    final dashboardDone = dashboardBloc.stream.firstWhere(
      (state) => state.status != HomeDashboardStatus.loading,
    );
    dashboardBloc.add(const LoadHomeDashboard());
    unawaited(AmolDailyStore.instance.load());

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
                      HomeFeatureCardSlider(
                        height: 350.h,
                        children: [
                          KeyedSubtree(
                            key: ValueKey('fardh-prayer-$_refreshTick'),
                            child: const _FardhPrayerCard(),
                          ),
                          const _HadithReadingCard(),
                          const _QuranCard(),
                          KeyedSubtree(
                            key: ValueKey('nafl-more-$_refreshTick'),
                            child: const _NaflMoreCard(),
                          ),
                          const _ZikrCard(),
                          const _SunnahWitrCard(),
                          const _QuizCard(),
                        ],
                      ),
                      // SizedBox(height: 14.h),
                      // const HomeProgressSection(),
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

/// Opens the Amol tracker with [section] popped to the front.
void _openTracker(BuildContext context, AmalSection section) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AmolTrackingScreen(selectedSection: section),
    ),
  );
}

/// Fardh-prayer card: [AmalTrackerCardContent] over [HomeGradientShape],
/// fed from the home dashboard when it has loaded. Each bar shows only the
/// user's tracking status: dark green when tracked, soft red when its time has
/// passed untracked. Prayer times are the same Aladhan times (and on-device
/// cache) as [PrayerTimeCard].
class _FardhPrayerCard extends StatefulWidget {
  const _FardhPrayerCard();

  @override
  State<_FardhPrayerCard> createState() => _FardhPrayerCardState();
}

class _FardhPrayerCardState extends State<_FardhPrayerCard> {
  DailyPrayerTimes? _times;
  Timer? _clockTimer;
  DateTime _now = bangladeshNow();

  static const _itemKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  @override
  void initState() {
    super.initState();
    _loadTimes();
    AmolDailyStore.instance
      ..addListener(_onStoreChanged)
      ..ensureLoaded();
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

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AmolDailyStore.instance.removeListener(_onStoreChanged);
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
    final minuteNow = _now.hour * 60 + _now.minute;
    // Tracked prayers, from the shared daily checklist (updates when the user
    // ticks one in the tracker).
    final completedKeys = {
      for (final item
          in AmolDailyStore.instance.pillar('fardh_prayer')?.items ??
              const <AmolItem>[])
        if (item.isCompleted) item.itemKey,
    };
    final prayers = [
      for (final (i, prayer) in PrayerBarData.defaults.indexed)
        PrayerBarData(
          name: prayer.name,
          points: prayer.points,
          completed: completedKeys.contains(_itemKeys[i]),
          // Red once its time has started (or passed) without being tracked;
          // a prayer that hasn't started yet stays the default colour.
          isMissed:
              times != null &&
              minuteNow >=
                  prayerStart(PrayerPeriod.values[i], times).totalMinutes,
        ),
    ];

    return GestureDetector(
      onTap: () => _openTracker(context, AmalSection.fardhPrayer),
      child: HomeGradientShape(
        child: AmalTrackerCardContent(
          percentage: fardh?.percentage ?? 0,
          completedLabel: fardh?.formattedSubtext,
          prayers: prayers,
          onOpenDashboard: () => _openTracker(context, AmalSection.fardhPrayer),
          onPrayerTap: (prayer) => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AmolTrackingScreen(
                selectedSection: AmalSection.fardhPrayer,
                selectedPrayer: prayer.name,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hadith-reading card: [HadithReadingCardContent] over [HomeGradientShape],
/// fed from the `hadith` pillar of the home dashboard when it has loaded.
class _HadithReadingCard extends StatelessWidget {
  const _HadithReadingCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeDashboardBloc>().state;
    final dashboard = state.hasData ? state.dashboard : null;
    PillarCard? hadith;
    for (final p in dashboard?.pillarCards ?? const <PillarCard>[]) {
      if (p.pillarKey == 'hadith') hadith = p;
    }

    String fmt(num v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const AmolTrackingScreen(selectedSection: AmalSection.hadith),
        ),
      ),
      child: HomeGradientShape(
        child: HadithReadingCardContent(
          percentage: hadith?.percentage ?? 0,
          onOpenDashboard: () => _openTracker(context, AmalSection.hadith),
          counter: hadith == null
              ? '0/7'
              : '${fmt(hadith.points)}/${fmt(hadith.maxPoints)}',
          readingTimeLabel: hadith?.formattedSubtext ?? '',
        ),
      ),
    );
  }
}

/// Quran card: [QuranCardContent] over [HomeGradientShape], fed from the
/// `quran` pillar of the home dashboard when it has loaded.
class _QuranCard extends StatelessWidget {
  const _QuranCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeDashboardBloc>().state;
    final dashboard = state.hasData ? state.dashboard : null;
    PillarCard? quran;
    for (final p in dashboard?.pillarCards ?? const <PillarCard>[]) {
      if (p.pillarKey == 'quran') quran = p;
    }

    String fmt(num v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';
    final max = quran?.maxPoints ?? 0;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const AmolTrackingScreen(selectedSection: AmalSection.quran),
        ),
      ),
      child: HomeGradientShape(
        child: QuranCardContent(
          onOpenQuran: () => _openTracker(context, AmalSection.quran),
          counter: quran == null ? '0/11' : '${fmt(quran.points)}/${fmt(max)}',
          progress: quran == null || max <= 0
              ? 0
              : (quran.points / max).toDouble(),
          readingTimeLabel: quran?.formattedSubtext ?? '',
        ),
      ),
    );
  }
}

/// Nafl and more card: [NaflMoreCardContent] over [HomeGradientShape], fed
/// from the `nafl_and_more` pillar of the home dashboard when it has loaded.
class _NaflMoreCard extends StatefulWidget {
  const _NaflMoreCard();

  @override
  State<_NaflMoreCard> createState() => _NaflMoreCardState();
}

class _NaflMoreCardState extends State<_NaflMoreCard> {
  @override
  void initState() {
    super.initState();
    AmolDailyStore.instance
      ..addListener(_onStoreChanged)
      ..ensureLoaded();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AmolDailyStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  /// The items and each one's tracked state come from the shared daily
  /// checklist (`nafl_and_more` pillar).
  List<NaflItemData> get _items => [
    for (final item
        in AmolDailyStore.instance.pillar('nafl_and_more')?.items ??
            const <AmolItem>[])
      NaflItemData(
        name: item.title,
        points: item.maxPoints,
        completed: item.isCompleted,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeDashboardBloc>().state;
    final dashboard = state.hasData ? state.dashboard : null;
    PillarCard? nafl;
    for (final p in dashboard?.pillarCards ?? const <PillarCard>[]) {
      if (p.pillarKey == 'nafl_and_more') nafl = p;
    }

    String fmt(num v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';
    return GestureDetector(
      onTap: () => _openTracker(context, AmalSection.naflAndMore),
      child: HomeGradientShape(
        child: NaflMoreCardContent(
          percentage: nafl?.percentage ?? 0,
          onOpenDashboard: () => _openTracker(context, AmalSection.naflAndMore),
          counter: nafl == null
              ? '0/7'
              : '${fmt(nafl.points)}/${fmt(nafl.maxPoints)}',
          items: _items,
        ),
      ),
    );
  }
}

/// Zikr card: [ZikrCardContent] over [HomeGradientShape], fed from the
/// `zikr` pillar of the home dashboard when it has loaded. The tracker has no
/// Zikr section, so it opens the Zikr feature instead.
class _ZikrCard extends StatefulWidget {
  const _ZikrCard();

  @override
  State<_ZikrCard> createState() => _ZikrCardState();
}

class _ZikrCardState extends State<_ZikrCard> {
  @override
  void initState() {
    super.initState();
    AmolDailyStore.instance
      ..addListener(_onStoreChanged)
      ..ensureLoaded();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AmolDailyStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeDashboardBloc>().state;
    final dashboard = state.hasData ? state.dashboard : null;
    PillarCard? zikr;
    for (final p in dashboard?.pillarCards ?? const <PillarCard>[]) {
      if (p.pillarKey == 'zikr') zikr = p;
    }
    // The tracker's `zikr` pillar (when the server sends one) supplies the
    // list and each zikr's tracked state; without it the card keeps its five
    // numbered placeholders and the Home dashboard's numbers.
    final tracked = AmolDailyStore.instance.pillar('zikr');
    final items = tracked == null || tracked.items.isEmpty
        ? ZikrItemData.placeholders
        : [
            for (final item in tracked.items)
              ZikrItemData(name: item.title, completed: item.isCompleted),
          ];

    String fmt(num v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';
    return GestureDetector(
      // With a tracker pillar, open the tracker on it (where Zikr is ticked);
      // otherwise the Zikr feature.
      onTap: () => tracked == null
          ? Navigator.of(context).pushNamed(RouteNames.zikr)
          : _openTracker(context, AmalSection.zikr),
      child: HomeGradientShape(
        child: ZikrCardContent(
          percentage: tracked?.percentage ?? zikr?.percentage ?? 0,
          counter: zikr == null
              ? '0/7'
              : '${fmt(zikr.points)}/${fmt(zikr.maxPoints)}',
          items: items,
          onOpenZikr: tracked == null
              ? null
              : () => _openTracker(context, AmalSection.zikr),
        ),
      ),
    );
  }
}

/// Sunnah and Witr card: [SunnahWitrCardContent] over [HomeGradientShape],
/// fed from the `sunnah_witr` pillar of the home dashboard when it has loaded.
class _SunnahWitrCard extends StatefulWidget {
  const _SunnahWitrCard();

  @override
  State<_SunnahWitrCard> createState() => _SunnahWitrCardState();
}

class _SunnahWitrCardState extends State<_SunnahWitrCard> {
  /// Pill label -> the tracker `itemKey`s behind it. Isha's pill (+2) covers
  /// the Isha Sunnah and Witr; only the Isha Sunnah drives its colour.
  static const _pillItems = {
    'Fajr': ['fajr_sunnah'],
    'Duhr': ['dhuhr_sunnah'],
    'Asr': ['asr_sunnah'],
    'Magrib': ['maghrib_sunnah'],
    'Esa': ['isha_sunnah', 'witr'],
  };

  @override
  void initState() {
    super.initState();
    AmolDailyStore.instance
      ..addListener(_onStoreChanged)
      ..ensureLoaded();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AmolDailyStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  /// Per-prayer points and tracked state from the shared daily checklist
  /// (`sunnah_witr` pillar); empty until it loads.
  List<SunnahPrayerData> get _prayers {
    final items = AmolDailyStore.instance.pillar('sunnah_witr')?.items;
    if (items == null) return const [];
    final byKey = {for (final item in items) item.itemKey: item};
    return [
      for (final entry in _pillItems.entries)
        if (byKey[entry.value.first] != null)
          SunnahPrayerData(
            prayerName: entry.key,
            points: [
              for (final key in entry.value) byKey[key]?.maxPoints ?? 0,
            ].fold<num>(0, (sum, v) => sum + v),
            sunnahCompleted: byKey[entry.value.first]!.isCompleted,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeDashboardBloc>().state;
    final dashboard = state.hasData ? state.dashboard : null;
    PillarCard? sunnah;
    for (final p in dashboard?.pillarCards ?? const <PillarCard>[]) {
      if (p.pillarKey == 'sunnah_witr') sunnah = p;
    }

    String fmt(num v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';
    return GestureDetector(
      onTap: () => _openTracker(context, AmalSection.sunnahWitr),
      child: HomeGradientShape(
        child: SunnahWitrCardContent(
          percentage: sunnah?.percentage ?? 0,
          counter: sunnah == null
              ? '0/6'
              : '${fmt(sunnah.points)}/${fmt(sunnah.maxPoints)}',
          prayers: _prayers,
        ),
      ),
    );
  }
}

/// Quiz card: [QuizCardContent] over [HomeGradientShape], fed from the `quiz`
/// pillar of the home dashboard when it has loaded.
class _QuizCard extends StatelessWidget {
  const _QuizCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeDashboardBloc>().state;
    final dashboard = state.hasData ? state.dashboard : null;
    PillarCard? quiz;
    for (final p in dashboard?.pillarCards ?? const <PillarCard>[]) {
      if (p.pillarKey == 'quiz') quiz = p;
    }

    String fmt(num v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';
    return GestureDetector(
      onTap: () => _openTracker(context, AmalSection.quiz),
      child: HomeGradientShape(
        child: QuizCardContent(
          percentage: quiz?.percentage ?? 0,
          counter: quiz == null
              ? '0/7'
              : '${fmt(quiz.points)}/${fmt(quiz.maxPoints)}',
        ),
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
