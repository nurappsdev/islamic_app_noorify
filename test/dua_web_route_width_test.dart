import 'package:flutter_test/flutter_test.dart';

import 'package:tuhfatul_muslim/core/constants/app_routes.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';

/// Every Dua route lays itself out against the browser's own width, so none
/// may be wrapped in `WebMobileCanvas` - the 600px phone-shaped column that
/// other routes still use until their own responsive work begins.
///
/// `AppRoutes.isFullWidthWebRoute` is the rule that decides; it is checked
/// directly rather than by building the screens, which would need Hive and
/// the whole dependency graph just to answer a routing question.
const _duaRoutes = <String>[
  RouteNames.dua,
  RouteNames.duaDashboard,
  RouteNames.duaAnalyticsDashboard,
  RouteNames.duaRecitationHistory,
  RouteNames.duaAllCategory,
  RouteNames.duaCategoryDuas,
  RouteNames.duaFeatured,
  RouteNames.duaGroup,
  RouteNames.duaGroupAllDua,
  RouteNames.duaReader,
  RouteNames.duaSaved,
  RouteNames.duaPlanner,
  RouteNames.duaPlanCreate,
  RouteNames.duaPlanDetail,
];

void main() {
  group('Dua routes use the full browser width', () {
    for (final name in _duaRoutes) {
      test(name, () {
        expect(
          AppRoutes.isFullWidthWebRoute(name),
          isTrue,
          reason: '$name would still be capped at 600px on the browser',
        );
      });
    }

    test('a new Dua route is covered by the prefix, not a list', () {
      // The rule matches on the `/dua` prefix, so a route added later is
      // responsive by default rather than silently letterboxed.
      expect(AppRoutes.isFullWidthWebRoute('/dua/something-new'), isTrue);
    });
  });

  group('other routes keep the mobile canvas', () {
    test('the already-responsive routes are still exempt', () {
      expect(AppRoutes.isFullWidthWebRoute(RouteNames.splash), isTrue);
      expect(AppRoutes.isFullWidthWebRoute(RouteNames.home), isTrue);
      expect(
        AppRoutes.isFullWidthWebRoute(RouteNames.onboardingHadith),
        isTrue,
      );
    });

    test('a route outside Dua is not made full width by accident', () {
      for (final name in [
        RouteNames.settings,
        RouteNames.profile,
        // Guards against a bare `startsWith` matching a sibling feature
        // whose name merely begins with the same letters.
        '/duaa',
        '/dua-extra',
      ]) {
        expect(
          AppRoutes.isFullWidthWebRoute(name),
          isFalse,
          reason: '$name should keep the mobile canvas',
        );
      }
    });

    test('a null route name keeps the canvas', () {
      expect(AppRoutes.isFullWidthWebRoute(null), isFalse);
    });
  });
}
