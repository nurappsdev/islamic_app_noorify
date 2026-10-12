import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One destination of an [AppBottomNavBar].
class AppBottomNavItem {
  const AppBottomNavItem({
    this.icon,
    this.iconAsset,
    this.iconAssetColor,
    required this.label,
    this.onTap,
    this.key,
  }) : assert(
         icon != null || iconAsset != null,
         'Provide either icon or iconAsset.',
       );

  /// Used when [iconAsset] is null.
  final IconData? icon;

  /// Image asset path; takes precedence over [icon] when set.
  final String? iconAsset;

  /// Optional tint for [iconAsset]. Null keeps the asset's own colors.
  final Color? iconAssetColor;

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
        margin: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 10.h),
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(
          color: _barColor,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: _shadowColor.withValues(alpha: .16),
              blurRadius: 12.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, bounds) {
            // Too narrow for a label: the selected item shows its icon only.
            // Compared against the real available width, not a design-size
            // value, so this threshold is intentionally left unscaled.
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
          borderRadius: BorderRadius.circular(22.r),
          child: InkWell(
            key: item.key,
            borderRadius: BorderRadius.circular(22.r),
            onTap: item.onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  item.iconAsset != null
                      ? Image.asset(
                          item.iconAsset!,
                          width: 20.sp,
                          height: 20.sp,
                          fit: BoxFit.contain,
                          color: item.iconAssetColor,
                          colorBlendMode: item.iconAssetColor != null
                              ? BlendMode.srcIn
                              : null,
                        )
                      : Icon(item.icon, color: Colors.white, size: 20.sp),
                  if (selected && showLabel) ...[
                    SizedBox(width: 5.w),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
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
