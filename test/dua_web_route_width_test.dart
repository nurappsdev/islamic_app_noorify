import 'package:flutter/material.dart';
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

/// The five destinations on [DuaBottomNav], in its own order.
const _duaNavDestinations = <String, String>{
  'Dua Home': RouteNames.duaDashboard,
  'Explore': RouteNames.duaAllCategory,
  'Saved': RouteNames.duaSaved,
  'Planner': RouteNames.duaPlanner,
  'Dashboard': RouteNames.duaAnalyticsDashboard,
};

void _expectInstant(String name, {required String label}) {
  final route = AppRoutes.onGenerateRoute(RouteSettings(name: name));
  // Only a PageRouteBuilder exposes `transitionDuration` without being
  // attached to a navigator; MaterialRouteTransitionMixin reads the theme
  // through `navigator!` and would throw here. So the type check is also
  // the assertion that this is not an animated Material route.
  expect(
    route,
    isA<PageRouteBuilder<void>>(),
    reason:
        '$label animates a full page transition; switching tabs then '
        'builds the outgoing and incoming screen together and stalls the '
        'browser. Use _instantPage, as Home and Hadith do.',
  );
  expect(
    (route as PageRouteBuilder<void>).transitionDuration,
    Duration.zero,
    reason: '$label should swap in place',
  );
}

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

    test('and they are the routes whose type grows with the window', () {
      // `AppRoutes` wraps a Dua route in `DuaWebTypography` on the browser,
      // by the same prefix rule; a route outside Dua keeps phone type.
      for (final name in _duaRoutes) {
        expect(AppRoutes.isDuaRoute(name), isTrue, reason: name);
      }
      for (final name in [
        RouteNames.home,
        RouteNames.splash,
        RouteNames.settings,
        '/duaa',
        '/dua-extra',
        null,
      ]) {
        expect(AppRoutes.isDuaRoute(name), isFalse, reason: '$name');
      }
    });

    test('a new Dua route is covered by the prefix, not a list', () {
      // The rule matches on the `/dua` prefix, so a route added later is
      // responsive by default rather than silently letterboxed.
      expect(AppRoutes.isFullWidthWebRoute('/dua/something-new'), isTrue);
    });
  });

  group('bottom-nav tabs swap in place, so the browser does not stall', () {
    _duaNavDestinations.forEach((label, name) {
      test('$label ($name)', () => _expectInstant(name, label: label));
    });

    test('they match the Home and Hadith tab bars', () {
      // The convention this follows; if those ever become animated, the
      // Dua tabs were not the odd ones out after all.
      _expectInstant(RouteNames.home, label: 'Home');
      _expectInstant(RouteNames.hadithLibrary, label: 'Hadith library');
    });

    test('a Dua detail route still animates', () {
      // Only the tab destinations swap instantly; pushing a dua to read
      // keeps the normal page transition.
      expect(
        AppRoutes.onGenerateRoute(
          const RouteSettings(name: RouteNames.duaReader),
        ),
        isA<MaterialPageRoute<void>>(),
      );
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
