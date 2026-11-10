import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/widgets/app_bottom_nav_bar.dart';

/// Navigation bar for the Dua flow (design `devImg/img_35.png`).
///
/// Destinations follow the mockup order: Dua Home, Explore, Save, Planner,
/// and Dashboard. Keeping this order here makes the selected index consistent
/// across every Dua screen that shows the bar.
class DuaBottomNav extends StatelessWidget {
  const DuaBottomNav({super.key, this.selectedIndex = 0});

  /// 0: Dua Home, 1: Explore, 2: Save, 3: Planner, 4: Dashboard.
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
          label: '${appText.duaIntroTitle} ${appText.home}',
          onTap: go(0, RouteNames.duaDashboard),
        ),
        AppBottomNavItem(
          icon: Icons.search_rounded,
          label: appText.duaExplore,
          onTap: go(1, RouteNames.duaAllCategory),
        ),
        AppBottomNavItem(
          icon: Icons.bookmark_border_rounded,
          label: appText.saved,
          onTap: go(2, RouteNames.duaSaved),
        ),
        AppBottomNavItem(
          icon: Icons.auto_stories_outlined,
          label: appText.planner,
          onTap: go(3, RouteNames.duaPlanner),
        ),
        AppBottomNavItem(
          icon: Icons.pie_chart_outline_rounded,
          label: appText.dashboard,
          onTap: go(4, RouteNames.duaAnalyticsDashboard),
        ),
      ],
    );
  }
}
