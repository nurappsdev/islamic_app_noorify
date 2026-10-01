import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/widgets/login_required_dialog.dart';
import 'package:tuhfatul_muslim/core/auth/auth_feature.dart';
import 'package:tuhfatul_muslim/core/widgets/app_bottom_nav_bar.dart';

/// Navigation bar shown on the app's main Home screen.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, this.selectedIndex = 0});

  /// Home, Quran, Hadith, Leaderboard.
  static const leaderboardIndex = 3;

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return AppBottomNavBar(
      selectedIndex: selectedIndex,
      items: [
        AppBottomNavItem(
          icon: Icons.home_outlined,
          label: appText.home,
          onTap: () => _goTo(context, RouteNames.home),
        ),
        AppBottomNavItem(
          icon: Icons.menu_book_outlined,
          label: appText.categoryQuran,
          onTap: () => _goTo(context, RouteNames.quranSurahs),
        ),
        // Opened over Home, so back returns to it.
        AppBottomNavItem(
          icon: Icons.local_library_outlined,
          label: appText.categoryHadith,
          onTap: () => Navigator.of(context).pushNamed(RouteNames.hadith),
        ),
        AppBottomNavItem(
          icon: Icons.leaderboard_rounded,
          label: appText.leaderboard,
          onTap: () => _goTo(
            context,
            RouteNames.leaderboard,
            loginFeature: AuthFeatures.leaderboard,
          ),
        ),
      ],
    );
  }
}

Future<void> _goTo(
  BuildContext context,
  String routeName, {
  String? loginFeature,
}) async {
  if (ModalRoute.of(context)?.settings.name == routeName) return;
  if (loginFeature != null &&
      !await requireLogin(context, feature: loginFeature)) {
    return;
  }
  if (!context.mounted) return;
  Navigator.of(context).pushReplacementNamed(routeName);
}
