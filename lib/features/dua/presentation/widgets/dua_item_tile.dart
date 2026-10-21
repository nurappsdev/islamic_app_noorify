import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

/// The numbered, pastel-background dua row shown in a Dua group's "All dua"
/// list (design `devImg/img_18.png`).
class DuaItemTile extends StatelessWidget {
  const DuaItemTile({
    super.key,
    required this.index,
    required this.name,
    this.subtitle,
    this.onTap,
  });

  /// This tile's position in its list (0-based) — picks its background and
  /// badge color from [_palette] so the list reads as alternating color rows,
  /// the same cycling-by-index pattern as `DuaCategoryTile`.
  final int index;

  final String name;

  /// A short preview line under [name] (e.g. the dua's first translated
  /// line); hidden when null/empty.
  final String? subtitle;

  final VoidCallback? onTap;

  static const _palette = [
    _ItemPalette(bg: Color(0xFFFBDCE7), badge: Color(0xFF2E6359)),
    _ItemPalette(bg: Color(0xFFFBE8BE), badge: Color(0xFF2B3A6B)),
    _ItemPalette(bg: Color(0xFFDCEEC0), badge: Color(0xFF2F5233)),
    _ItemPalette(bg: Color(0xFFD3E6F5), badge: Color(0xFF4B3A6B)),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _palette[index % _palette.length];
    final subtitleText = subtitle;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(palette.bg),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.surfaceColor(palette.badge),
                shape: BoxShape.circle,
              ),
              child: Text(
                context.localizedDigits('${index + 1}'),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: context.inkColor(Colors.white),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: context.inkColor(const Color(0xFF2C3320)),
                    ),
                  ),
                  if (subtitleText != null && subtitleText.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: context.inkColor(const Color(0xFF5D6B44)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.chevron_right_rounded,
              color: context.inkColor(palette.badge),
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemPalette {
  const _ItemPalette({required this.bg, required this.badge});

  final Color bg;
  final Color badge;
}
