import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/widgets/app_bottom_nav_bar.dart';

/// Navigation bar dedicated to the Zikr flow.
///
/// Index 0 = the Zikr home (the same way the Hadith library is index 0 of
/// [HadithBottomNav]); 1 = the Zikr planner.
///
/// The Zikr stats dashboard (formerly index 2, [RouteNames.zikrStats]) is
/// temporarily hidden from this bar — its tab below is commented out, not
/// deleted. [ZikrStatsScreen] and its route are untouched; re-add the item
/// below to bring the tab back.
class ZikrBottomNav extends StatelessWidget {
  const ZikrBottomNav({super.key, this.selectedIndex = 0});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    VoidCallback? go(int index, String route) => selectedIndex == index
        ? null
        : () => Navigator.of(context).pushReplacementNamed(route);

    return AppBottomNavBar(
      selectedIndex: selectedIndex,
      items: [
        AppBottomNavItem(
          icon: Icons.home_outlined,
          label: appText.home,
          onTap: go(0, RouteNames.zikrDashboard),
        ),
        AppBottomNavItem(
          icon: Icons.fact_check_outlined,
          label: appText.planner,
          onTap: go(1, RouteNames.zikrPlanner),
        ),
        // Dashboard tab — temporarily hidden, not deleted. Uncomment to
        // restore it (and change the Home/Planner `go` calls above back to
        // index-aware ones if this is re-enabled while index 2 exists again).
        // AppBottomNavItem(
        //   icon: Icons.grid_view_rounded,
        //   label: appText.dashboard,
        //   onTap: go(2, RouteNames.zikrStats),
        // ),
      ],
    );
  }
}
