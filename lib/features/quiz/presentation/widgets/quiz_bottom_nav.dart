import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/widgets/app_bottom_nav_bar.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/screens/quiz_shell.dart';

/// Navigation bar dedicated to the Quiz & Learn flow.
///
/// Quiz Categories is the Quiz flow's Home destination, at index 0. The bar
/// lives once in [QuizShell]; a page pushed over the section can show its own
/// copy, whose taps return to the section.
class QuizBottomNav extends StatelessWidget {
  const QuizBottomNav({super.key, this.selectedIndex = 0, this.onSelected});

  /// Home, Learn, Planner, Dashboard.
  static const tabCount = 4;

  final int selectedIndex;

  /// Called with the tapped tab; without it the tap goes through
  /// [QuizShell.switchTo].
  final ValueChanged<int>? onSelected;

  static List<({IconData icon, IconData? selectedIcon, String label})> _items(
    AppText appText,
  ) => [
    (
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: appText.home,
    ),
    (
      icon: Icons.emoji_objects_outlined,
      selectedIcon: null,
      label: appText.learn,
    ),
    (
      icon: Icons.assignment_turned_in_outlined,
      selectedIcon: null,
      label: appText.planner,
    ),
    (
      icon: Icons.grid_view_outlined,
      selectedIcon: null,
      label: appText.dashboard,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppBottomNavBar(
      selectedIndex: selectedIndex,
      items: [
        for (final (index, item) in _items(AppText.of(context)).indexed)
          AppBottomNavItem(
            icon: index == selectedIndex
                ? item.selectedIcon ?? item.icon
                : item.icon,
            label: item.label,
            onTap: selectedIndex == index
                ? null
                : () => onSelected != null
                      ? onSelected!(index)
                      : QuizShell.switchTo(context, index),
          ),
      ],
    );
  }
}
