import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/features/promo_banner/domain/entities/promo_banner.dart';
import 'package:tuhfatul_muslim/features/promo_banner/domain/repositories/promo_banner_repository.dart';
import 'package:tuhfatul_muslim/features/promo_banner/promo_banner_dependencies.dart';

/// The in-app destinations an admin may point a banner at, keyed by the path
/// the API sends. The API's own vocabulary is plural (`/duas`, `/hadiths`)
/// while this app's routes are not, so both spellings are listed.
///
/// This table is an allow-list on purpose. `onGenerateRoute` falls through to
/// the sign-in screen for a name it does not know, so pushing an unrecognised
/// path would throw a signed-in user out of the app over a typo in a banner.
/// A path that is not here does nothing at all.
const _appRoutes = <String, String>{
  '/duas': RouteNames.dua,
  '/dua': RouteNames.dua,
  '/quran': RouteNames.quran,
  '/hadiths': RouteNames.hadith,
  '/hadith': RouteNames.hadith,
  '/zakat': RouteNames.zakatCalculator,
  '/zakat-calculator': RouteNames.zakatCalculator,
  '/zikr': RouteNames.zikr,
  '/tasbih': RouteNames.tasbih,
  '/leaderboard': RouteNames.leaderboard,
  '/prayer-times': RouteNames.prayerTimes,
  '/quiz': RouteNames.winQuiz,
  '/learning': RouteNames.learning,
};

/// `/Duas/` and `/duas?utm=x` are the same destination as `/duas`.
String _normalize(String path) {
  final withoutQuery = path.split('?').first.split('#').first.trim();
  final lower = withoutQuery.toLowerCase();
  final leading = lower.startsWith('/') ? lower : '/$lower';
  return leading.length > 1 && leading.endsWith('/')
      ? leading.substring(0, leading.length - 1)
      : leading;
}

/// The route [banner] opens inside the app, or `null` when it opens nothing
/// in the app.
///
/// The configured [PromoBanner.action] decides the intent, but the value
/// decides the kind: an `app_screen` banner carrying a full web address is
/// still a web address, and a `url` banner carrying `/duas` is still a
/// screen. [PromoBannerAction.none] always wins.
String? promoBannerRouteFor(PromoBanner banner) {
  if (banner.action == PromoBannerAction.none) return null;
  final raw = banner.actionUrl.trim();
  if (raw.isEmpty || raw.contains('://')) return null;
  return _appRoutes[_normalize(raw)];
}

/// The web address [banner] opens outside the app, or `null`.
///
/// Only `http`/`https` are opened: the address comes from the server, and
/// handing an arbitrary scheme to the platform launcher is how a banner ends
/// up firing an `intent://` or `file://` URI nobody vetted.
Uri? promoBannerUrlFor(PromoBanner banner) {
  if (banner.action == PromoBannerAction.none) return null;
  final uri = Uri.tryParse(banner.actionUrl.trim());
  if (uri == null || !uri.hasAuthority) return null;
  return uri.scheme == 'http' || uri.scheme == 'https' ? uri : null;
}

/// Whether tapping [banner] leads anywhere. A banner that leads nowhere is
/// drawn without a tap target rather than swallowing taps silently.
bool promoBannerIsTappable(PromoBanner banner) =>
    promoBannerRouteFor(banner) != null || promoBannerUrlFor(banner) != null;

/// Opens [banner] and records the tap.
///
/// The click is sent first and never awaited: the count must not delay the
/// screen change, and a failed count must not cost the user their tap.
Future<void> openPromoBanner(
  BuildContext context,
  PromoBanner banner, {
  PromoBannerRepository? repository,
}) async {
  final route = promoBannerRouteFor(banner);
  final url = promoBannerUrlFor(banner);
  if (route == null && url == null) return;

  unawaited((repository ?? promoBannerRepository).trackClick(banner.id));

  if (route != null) {
    Navigator.of(context).pushNamed(route);
    return;
  }
  await launchUrl(url!, mode: LaunchMode.externalApplication);
}
