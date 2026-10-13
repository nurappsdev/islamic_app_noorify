import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

/// The pastel-green dua card shown on the dashboard's Featured Dua row and on
/// the full Featured Dua list (design `img_1.png` / `img_3.png`).
class DuaFeaturedCard extends StatelessWidget {
  const DuaFeaturedCard({super.key, required this.featured, this.onExplore});

  final DuaFeaturedModel featured;

  /// Called when the "Explore" pill is tapped — opens this dua on
  /// [DuaReaderScreen].
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFDCE8C4)),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: context.lineColor(Color(0xFFC7D6A6))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34.r,
                height: 34.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.surfaceColor(Colors.white),
                  borderRadius: BorderRadius.circular(9.r),
                  border: Border.all(
                    color: context.lineColor(Color(0xFFC7D6A6)),
                  ),
                ),
                child: _FeaturedIcon(
                  iconUrl: featured.iconUrl ?? featured.category?.iconUrl,
                  color: context.inkColor(Color(0xFF6B7A4A)),
                  size: 18.sp,
                ),
              ),
              InkWell(
                onTap: onExplore,
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: context.surfaceColor(Colors.white),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFF3C4A28)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        appText.duaExplore,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.north_east_rounded, size: 13.sp),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Text(
            context.localized(featured.title),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.inkColor(Color(0xFF3C4A28)),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dua's `iconUrl` (falling back to its category's), or a generic badge
/// icon when there is none or it fails to load.
class _FeaturedIcon extends StatelessWidget {
  const _FeaturedIcon({
    required this.iconUrl,
    required this.color,
    required this.size,
  });

  final String? iconUrl;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.badge_outlined, color: color, size: size);
    final url = iconUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return icon;
    return Image.network(
      uri.toString(),
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => icon,
    );
  }
}
