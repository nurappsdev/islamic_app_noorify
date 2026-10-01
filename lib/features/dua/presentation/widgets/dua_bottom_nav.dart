import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/widgets/app_bottom_nav_bar.dart';

/// Navigation bar shown on the Dua dashboard (design `img_1.png`).
///
/// Only "Home" is wired today. The bookmark and category shortcuts match the
/// design but don't have dedicated screens yet, so they're rendered
/// non-interactive until a Saved Dua / quick-category screen exists.
class DuaBottomNav extends StatelessWidget {
  const DuaBottomNav({super.key, this.selectedIndex = 0});

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
          onTap: selectedIndex == 0
              ? null
              : () => Navigator.of(context).pushNamed(RouteNames.duaDashboard),
        ),
        AppBottomNavItem(
          icon: Icons.bookmark_border_rounded,
          label: appText.saved,
          onTap: selectedIndex == 1
              ? null
              : () => Navigator.of(context).pushNamed(RouteNames.duaSaved),
        ),
        // No Dua planner screen yet: shown, but not tappable.
        AppBottomNavItem(
          icon: Icons.fact_check_outlined,
          label: appText.planner,
        ),
      ],
    );
  }
}
