import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';

/// The bordered icon-and-label tile for a [DuaCategoryModel], shown on both
/// the dashboard's category preview grid and the full "All Category" grid
/// (design `img_1.png` / `img_2.png`).
class DuaCategoryTile extends StatelessWidget {
  const DuaCategoryTile({super.key, required this.category});

  final DuaCategoryModel category;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: category.id.isEmpty
          ? null
          : () => Navigator.of(context).pushNamed(
              RouteNames.duaCategoryDuas,
              arguments: DuaCategoryDuasArgs(category),
            ),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(Colors.white),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: context.lineColor(Color(0xFFE3E7D3))),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CategoryIcon(iconUrl: category.iconUrl, slug: category.slug),
            SizedBox(height: 10.h),
            Text(
              context.localized(category.name),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: context.inkColor(Color(0xFF5D6B44)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A category's `iconUrl` image, or a slug-based Material icon when there is
/// none or it fails to load (same pattern as `QuizCategoryIcon`).
class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.iconUrl, required this.slug});

  final String? iconUrl;
  final String slug;

  static const Color _color = Color(0xFF9BA85B);
  static const double _size = 34;

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
    final icon = Icon(_fallback, color: _color, size: _size.sp);
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
