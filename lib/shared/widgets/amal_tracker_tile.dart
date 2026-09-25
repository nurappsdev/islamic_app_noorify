import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/app_palette.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/widgets/amol_progress_ring.dart';

/// The Amal tracker card design: logo (or rank) tile, title + subtitle, and a
/// progress ring. Shared by the Home slider and the Amol tracking screens so
/// both always look exactly the same (radius, padding, ring, spacing).
class AmalTrackerTile extends StatelessWidget {
  const AmalTrackerTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progressLabel,
    required this.progress,
    this.leadingText,
  });

  final String title;
  final String subtitle;
  final String progressLabel;
  final double progress;

  /// Shown in the leading tile instead of the logo (e.g. a rank).
  final String? leadingText;

  static double get radius => 28.r;
  static double get ringSize => 68.r;
  static double get ringHoleSize => 40.r;
  static const ringStrokeFactor = .18;
  static double get horizontalPadding => 20.w;
  static double get verticalPadding => 16.h;
  static double get leadingSize => 50.r;
  static double get leadingGap => 14.w;
  static double get ringGap => 8.w;

  /// Height the tile needs; the Home slider (fixed-height page view) and its
  /// loading placeholder use it so padding changes really resize the card.
  static double get height => ringSize + 2 * verticalPadding;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    TextStyle text(double size, {FontWeight? weight, double? height}) =>
        TextStyle(
          color: palette.textPrimary,
          fontSize: size,
          fontWeight: weight,
          height: height,
        );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor(palette.tint),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.lineColor(palette.tint)),
      ),
      child: Row(
        children: [
          _LeadingTile(leadingText: leadingText),
          SizedBox(width: leadingGap),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text(13.sp),
                ),
                SizedBox(height: 5.h),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text(9.sp, height: 1.3),
                ),
              ],
            ),
          ),
          SizedBox(width: ringGap),
          AmolProgressRing(
            label: progressLabel,
            progress: progress,
            dimension: ringSize,
            holeDimension: ringHoleSize,
            strokeFactor: ringStrokeFactor,
            holeColor: palette.tint,
            labelStyle: text(9.sp, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _LeadingTile extends StatelessWidget {
  const _LeadingTile({this.leadingText});

  final String? leadingText;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: AmalTrackerTile.leadingSize,
      height: AmalTrackerTile.leadingSize,
      padding: EdgeInsets.all(leadingText == null ? 11.r : 0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.tintSoft,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: leadingText == null
          ? Image.asset(
              'assets/appLogo.png',
              fit: BoxFit.contain,
              color: context.inkColor(const Color(0xFF879461)),
            )
          : Text(
              leadingText!,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
