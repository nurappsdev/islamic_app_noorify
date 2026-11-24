// ANDROID / iOS ONLY - the Flutter Web build never renders anything in this
// file.
//
// The phone dashboard: one scrolling column of Home sections with the bottom
// navigation pinned over it. `home_screen_web.dart` does not reference a
// single name declared here, so a change in this file CANNOT move the Web
// layout.
//
// Entry point: `_MobileHomeDashboard`, picked by the `!kIsWeb` branch in
// `home_screen.dart`. The cards it arranges are shared and live in
// `home_screen_shared_cards.dart`.

part of 'home_screen.dart';

/// The original phone-only composition. Keeping it in a separate widget is
/// deliberate: Web layout changes below cannot alter Android or iOS geometry.
class _MobileHomeDashboard extends StatelessWidget {
  const _MobileHomeDashboard({
    required this.language,
    required this.refreshTick,
    required this.onRefresh,
  });

  final AppLanguage language;
  final int refreshTick;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColor.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(9.w, 10.h, 9.w, 92.h),
            child: Column(
              children: _homeSections(
                language: language,
                refreshTick: refreshTick,
              ),
            ),
          ),
        ),
        const Align(alignment: Alignment.bottomCenter, child: HomeBottomNav()),
      ],
    );
  }
}

List<Widget> _homeSections({
  required AppLanguage language,
  required int refreshTick,
}) => [
  const AmalTrackerCard(),
  SizedBox(height: 16.h),
  KeyedSubtree(
    key: ValueKey('prayer-time-card-${language.name}-$refreshTick'),
    child: const PrayerTimeCard(),
  ),
  SizedBox(height: 24.h),
  KeyedSubtree(
    key: ValueKey('prohibited-prayer-times-${language.name}-$refreshTick'),
    child: const ProhibitedPrayerTimesCard(),
  ),
  SizedBox(height: 16.h),
  // Collapses to nothing when the admin has no active banners, so the two
  // cards around it close up with no gap of its own.
  const PromoBannerCarousel(),
  HomeFeatureCardSlider(
    key: ValueKey('home-feature-slider-${language.name}'),
    height: 350.h,
    children: [
      KeyedSubtree(
        key: ValueKey('fardh-prayer-$refreshTick'),
        child: const _FardhPrayerCard(),
      ),
      const _SunnahWitrCard(),
      const _QuranCard(),
      const _HadithReadingCard(),
      KeyedSubtree(
        key: ValueKey('nafl-more-$refreshTick'),
        child: const _NaflMoreCard(),
      ),
      const _ZikrCard(),
      const _QuizCard(),
    ],
  ),
  SizedBox(height: 10.h),
  const HomeProgressSection(),
  SizedBox(height: 10.h),
  const HomeFeatureGrid(),
  SizedBox(height: 10.h),
];
