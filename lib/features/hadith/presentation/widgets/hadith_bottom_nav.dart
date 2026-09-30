import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/widgets/login_required_dialog.dart';
import 'package:tuhfatul_muslim/core/auth/auth_feature.dart';
import 'package:tuhfatul_muslim/core/widgets/app_bottom_nav_bar.dart';

/// Navigation bar dedicated to the Hadith flow.
///
/// The Hadith Library is this flow's Home destination at index 0; the Hadith
/// Planner sits at index 1 and is shown with its "Planner" label.
class HadithBottomNav extends StatelessWidget {
  const HadithBottomNav({super.key, this.selectedIndex = 0});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);

    // Opens [route], after sign-in when [feature] needs it.
    VoidCallback? go(int index, String route, [String? feature]) =>
        selectedIndex == index
        ? null
        : () async {
            if (feature != null &&
                !await requireLogin(context, feature: feature)) {
              return;
            }
            if (!context.mounted) return;
            Navigator.of(context).pushReplacementNamed(route);
          };

    return AppBottomNavBar(
      selectedIndex: selectedIndex,
      items: [
        AppBottomNavItem(
          icon: Icons.home_outlined,
          label: appText.home,
          onTap: go(0, RouteNames.hadithLibrary),
        ),
        AppBottomNavItem(
          icon: Icons.fact_check_outlined,
          label: appText.planner,
          onTap: go(1, RouteNames.hadithPlanner, AuthFeatures.hadithPlanner),
        ),
        AppBottomNavItem(
          icon: Icons.bookmark_border_rounded,
          label: appText.saved,
          onTap: go(2, RouteNames.hadithSaved),
        ),
        AppBottomNavItem(
          icon: Icons.grid_view_rounded,
          label: appText.dashboard,
          onTap: go(
            3,
            RouteNames.hadithDashboard,
            AuthFeatures.hadithDashboard,
          ),
        ),
      ],
    );
  }
}
