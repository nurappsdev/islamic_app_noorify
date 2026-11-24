// FLUTTER WEB ONLY - the Android and iOS builds never render anything in this
// file.
//
// The browser dashboard: two reading columns on a wide viewport, collapsing to
// one on a narrow one, rather than a stretched phone canvas. It arranges the
// SAME cards as the phone layout (`home_screen_shared_cards.dart`) inside
// Web-only chrome (`home_screen_web_chrome.dart`).
//
// Entry point: `_WebHomeDashboard`, picked by the `kIsWeb` branch in
// `home_screen.dart`.

part of 'home_screen.dart';

/// A desktop/tablet dashboard that reuses every existing Home feature and its
/// data source. Wide browsers receive two intentional reading columns rather
/// than a stretched phone canvas; compact browsers naturally collapse back to
/// one column.
class _WebHomeDashboard extends StatelessWidget {
  const _WebHomeDashboard({
    required this.language,
    required this.refreshTick,
    required this.onRefresh,
  });

  final AppLanguage language;
  final int refreshTick;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _WebHomeContent(
          language: language,
          refreshTick: refreshTick,
          onRefresh: onRefresh,
          showBottomNavigation: constraints.maxWidth < 760,
        );
      },
    );
  }
}

class _WebHomeContent extends StatelessWidget {
  const _WebHomeContent({
    required this.language,
    required this.refreshTick,
    required this.onRefresh,
    required this.showBottomNavigation,
  });

  final AppLanguage language;
  final int refreshTick;
  final RefreshCallback onRefresh;
  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _WebHomeBackground()),
        Column(
          children: [
            const _WebHomeTopBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                color: AppColor.primary,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumnLayout = constraints.maxWidth >= 760;
                    final threeColumnLayout = constraints.maxWidth >= 1080;
                    final prohibitedCard = KeyedSubtree(
                      key: ValueKey(
                        'prohibited-prayer-times-${language.name}-$refreshTick',
                      ),
                      child: const ProhibitedPrayerTimesCard(),
                    );
                    final prayerCard = KeyedSubtree(
                      key: ValueKey(
                        'prayer-time-card-${language.name}-$refreshTick',
                      ),
                      child: const PrayerTimeCard(),
                    );
                    final featureSlider = KeyedSubtree(
                      key: ValueKey(
                        'web-home-feature-slider-${language.name}-$refreshTick',
                      ),
                      child: _WebHomeFeatureSlider(refreshTick: refreshTick),
                    );

                    return SingleChildScrollView(
                      key: const ValueKey('web-home-scroll-view'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        18,
                        24,
                        showBottomNavigation ? 104 : 36,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1320),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // The desktop reference is deliberately read in
                                  // three vertical columns: progress and restricted
                                  // times on the left, today's prayer clock in the
                                  // middle, and Fardh progress on the right. Keep
                                  // the cards themselves untouched; only compose
                                  // them differently for Web.
                                  if (threeColumnLayout) ...[
                                    Row(
                                      key: const ValueKey(
                                        'web-home-fixed-prayer-layout',
                                      ),
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AmalTrackerCard(),
                                              SizedBox(height: 22),
                                              ProhibitedPrayerTimesCard(),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(child: prayerCard),
                                        const SizedBox(width: 24),
                                        Expanded(child: featureSlider),
                                      ],
                                    ),
                                  ] else if (twoColumnLayout) ...[
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AmalTrackerCard(),
                                              SizedBox(height: 22),
                                              ProhibitedPrayerTimesCard(),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(child: prayerCard),
                                      ],
                                    ),
                                    const SizedBox(height: 22),
                                    featureSlider,
                                  ] else ...[
                                    const AmalTrackerCard(),
                                    const SizedBox(height: 18),
                                    prohibitedCard,
                                    const SizedBox(height: 18),
                                    prayerCard,
                                    const SizedBox(height: 18),
                                    featureSlider,
                                  ],
                                  const SizedBox(height: 22),
                                  const PromoBannerCarousel(
                                    height: 180,
                                    padding: EdgeInsets.only(bottom: 22),
                                  ),
                                  const HomeFeatureGrid(
                                    columnMajor: true,
                                    webStyle: true,
                                  ),
                                  // Qibla compass and the calendar remain in the
                                  // Android/iOS Home only, per the Web design.
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          const _WebHomeFooter(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        if (showBottomNavigation)
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: const HomeBottomNav(),
            ),
          ),
      ],
    );
  }
}

/// The desktop right-hand card uses the same feature carousel as Android.
/// Hover pauses automatic movement; users can drag horizontally with a mouse
/// or swipe to choose a card themselves.
class _WebHomeFeatureSlider extends StatelessWidget {
  const _WebHomeFeatureSlider({required this.refreshTick});

  final int refreshTick;

  @override
  Widget build(BuildContext context) => HomeFeatureCardSlider(
    height: 350,
    children: [
      KeyedSubtree(
        key: ValueKey('fardh-prayer-web-$refreshTick'),
        child: const _FardhPrayerCard(),
      ),
      const _SunnahWitrCard(),
      const _QuranCard(),
      const _HadithReadingCard(),
      KeyedSubtree(
        key: ValueKey('nafl-more-web-$refreshTick'),
        child: const _NaflMoreCard(),
      ),
      const _ZikrCard(),
      const _QuizCard(),
    ],
  );
}

const _webFooterInk = Colors.white;
const _webFooterMutedInk = Colors.white;
const _webFooterAccent = Color(0xFFA8C98A);
const _webPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.tuhfatulmuslim.app';

Future<void> _openWebPlayStore() => launchUrl(
  Uri.parse(_webPlayStoreUrl),
  mode: LaunchMode.externalApplication,
);
