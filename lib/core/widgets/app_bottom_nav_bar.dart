import 'package:flutter/material.dart';

/// One destination of an [AppBottomNavBar].
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.key,
  });

  final IconData icon;
  final String label;

  /// Null leaves the item inert (the selected one, or a placeholder).
  final VoidCallback? onTap;

  /// Put on the item's tap target, for tests.
  final Key? key;
}

/// The app's one bottom bar, shared by every module (Home, Quran, Hadith,
/// Quiz, Zikr, Dua) so they look and size the same: an olive pill whose
/// selected item widens to show its label beside the icon. Modules keep their
/// own destinations and navigation; only the look lives here.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
  });

  final List<AppBottomNavItem> items;
  final int selectedIndex;

  static const _barColor = Color(0xffa1ae57);
  static const _selectedColor = Color(0xff5d886b);
  static const _shadowColor = Color(0xff889569);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _barColor,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: _shadowColor.withValues(alpha: .16),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, bounds) {
            // Too narrow for a label: the selected item shows its icon only.
            final showLabel = bounds.maxWidth >= 300;
            return Row(
              children: [
                for (final (index, item) in items.indexed)
                  Expanded(
                    flex: index == selectedIndex && showLabel ? 2 : 1,
                    child: _NavButton(
                      item: item,
                      selected: index == selectedIndex,
                      showLabel: showLabel,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.showLabel,
  });

  final AppBottomNavItem item;
  final bool selected, showLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Tooltip(
        message: item.label,
        child: Material(
          color: selected ? AppBottomNavBar._selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            key: item.key,
            borderRadius: BorderRadius.circular(28),
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: Colors.white, size: 24),
                  if (selected && showLabel) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
