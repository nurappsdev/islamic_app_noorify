import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';

/// The pastel, colored-background card for a [DuaCategoryModel], shown on
/// both the dashboard's category preview grid and the full "All Category"
/// grid (design `devImg/img_16.png` / `devImg/img_17.png`).
class DuaCategoryTile extends StatelessWidget {
  const DuaCategoryTile({super.key, required this.category, this.index = 0});

  final DuaCategoryModel category;

  /// This tile's position in its grid — picks its background/accent from
  /// [_palette] so the same category reads the same color on both the
  /// dashboard preview and the full "All Category" grid.
  final int index;

  static const _palette = [
    _CategoryPalette(bg: Color(0xFFE3DAF5), accent: Color(0xFF7C5FC4)),
    _CategoryPalette(bg: Color(0xFFFBDFD6), accent: Color(0xFFD97A4D)),
    _CategoryPalette(bg: Color(0xFFF8D9DF), accent: Color(0xFFCB5E7E)),
    _CategoryPalette(bg: Color(0xFFDCE8C4), accent: Color(0xFF6B8A3A)),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _palette[index % _palette.length];
    final description = category.description;

    return InkWell(
      onTap: category.id.isEmpty
          ? null
          : () => Navigator.of(context).pushNamed(
              RouteNames.duaCategoryDuas,
              arguments: DuaCategoryDuasArgs(category),
            ),
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: context.surfaceColor(palette.bg),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CategoryIcon(
                  iconUrl: category.iconUrl,
                  slug: category.slug,
                  color: context.inkColor(palette.accent),
                ),
                _CountBadge(count: category.totalDuasCount),
              ],
            ),
            SizedBox(height: 14.h),
            Text(
              context.localized(category.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: context.inkColor(palette.accent),
              ),
            ),
            if (!description.isEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                context.localized(description),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  height: 1.3,
                  color: context.inkColor(const Color(0xFF5D6B44)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryPalette {
  const _CategoryPalette({required this.bg, required this.accent});

  final Color bg;
  final Color accent;
}

/// The white pill showing a category's `totalDuasCount` (design `img_16.png`
/// / `img_17.png`).
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        context.localizedDigits('$count'),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: context.inkColor(const Color(0xFF3C4A28)),
        ),
      ),
    );
  }
}

/// A category's `iconUrl` image, or a slug-based Material icon when there is
/// none or it fails to load (same pattern as `QuizCategoryIcon`).
class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({
    required this.iconUrl,
    required this.slug,
    required this.color,
  });

  final String? iconUrl;
  final String slug;
  final Color color;

  static const double _size = 26;

  IconData get _fallback => switch (slug) {
    'sleep' => Icons.nightlight_round,
    'morning' => Icons.wb_sunny_outlined,
    'evening' => Icons.wb_twilight,
    'quranic' => Icons.menu_book_rounded,
    'ruqyah' => Icons.shield_outlined,
    'salah' => Icons.mosque_outlined,
    'food' => Icons.restaurant_outlined,
    'daily-life' => Icons.home_outlined,
    'travel' => Icons.flight_outlined,
    'forgiveness' => Icons.favorite_border_rounded,
    'distress' => Icons.healing_outlined,
    _ => Icons.menu_book_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final icon = Icon(_fallback, color: color, size: _size.sp);
    final url = iconUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return icon;
    return Image.network(
      uri.toString(),
      width: _size.sp,
      height: _size.sp,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => icon,
    );
  }
}
