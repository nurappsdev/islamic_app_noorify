import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/app_palette.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_progress_ring.dart';

/// The Amal tracker card design: logo (or rank) tile, title + subtitle, and a
/// progress ring. Shared by the Home slider and the Amol tracking screens so
/// both always look exactly the same (radius, padding, ring, spacing).
class AmalTrackerTile extends StatelessWidget {
  const AmalTrackerTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.userName,
    this.topBadgeText,
    this.showUserNameBadge = true,
    required this.progressLabel,
    required this.progress,
    this.leadingText,
  });

  final String title;
  final String subtitle;
  final String? userName;

  /// Optional replacement for the overlapping top badge. Home uses this for
  /// the GPS-resolved district/country while the tracker screens retain their
  /// user-name badge.
  final String? topBadgeText;
  final bool showUserNameBadge;
  final String progressLabel;
  final double progress;

  /// Shown in the leading tile instead of the logo (e.g. a rank).
  final String? leadingText;

  static double get radius => 24.r;
  static double get ringSize => 67.r;
  static double get ringHoleSize => 47.r;
  static const ringStrokeFactor = .18;
  static double get horizontalPadding => 18.w;
  static double get verticalPadding => 7.h;
  static double get leadingWidth => 62.w;
  static double get leadingHeight => 62.h;
  static double get leadingGap => 14.w;
  static double get ringGap => 12.w;
  // The name pill lives above the green card body. This keeps it clear of
  // the progress ring while still letting its bottom edge overlap the border.
  static double get badgeTopInset => 15.h;
  static double get badgeHeight => 28.h;

  /// The complete tile, including the reserved space for the overlapping
  /// user-name badge.
  static double get height => 110.h;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final progressTrack = context.surfaceColor(amolProgressTrackColor);
    final progressFill = context.inkColor(amolProgressFillColor);
    final textColor = context.inkColor(Colors.black);
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: badgeTopInset,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: context.surfaceColor(palette.tint),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: context.lineColor(palette.tint)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Keep both text columns usable on compact Android phones
                  // without changing the card's proportion on normal widths.
                  final compact = constraints.maxWidth < 330;
                  final logoWidth = 62.r;
                  final logoHeight = 62.r;
                  final progressSize = compact ? 58.r : ringSize;
                  final progressHoleSize = compact ? 40.r : ringHoleSize;
                  final logoGap = compact ? 10.r : leadingGap;
                  final progressGap = compact ? 10.r : ringGap;
                  return Row(
                    children: [
                      _LeadingTile(
                        leadingText: leadingText,
                        width: logoWidth,
                        height: logoHeight,
                        backgroundColor: progressTrack,
                        foregroundColor: progressFill,
                      ),
                      SizedBox(width: logoGap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 14.h),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: progressGap),
                      AmolProgressRing(
                        label: progressLabel,
                        progress: progress,
                        dimension: progressSize,
                        holeDimension: progressHoleSize,
                        strokeFactor: ringStrokeFactor,
                        holeColor: context.surfaceColor(palette.tint),
                        trackColor: progressTrack,
                        progressColor: progressFill,
                        labelStyle: TextStyle(
                          color: textColor,
                          fontSize: compact ? 11.sp : 14.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          if ((topBadgeText ?? '').trim().isNotEmpty)
            Positioned(
              top: 0,
              right: 20.w,
              child: _UserNameBadge(
                name: topBadgeText!.trim(),
                borderColor: amolNameBadgeBorderColor,
                textColor: textColor,
              ),
            )
          else if (showUserNameBadge && (userName ?? '').isNotEmpty)
            Positioned(
              top: 0,
              right: 20.w,
              child: _UserNameBadge(
                name: userName!,
                borderColor: amolNameBadgeBorderColor,
                textColor: textColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _LeadingTile extends StatelessWidget {
  const _LeadingTile({
    this.leadingText,
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String? leadingText;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(leadingText == null ? 16.r : 0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: leadingText == null
          ? Image.asset(
              'assets/appLogo.png',
              fit: BoxFit.contain,
              color: foregroundColor,
            )
          : Text(
              leadingText!,
              style: TextStyle(
                color: context.inkColor(palette.textPrimary),
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _UserNameBadge extends StatelessWidget {
  const _UserNameBadge({
    required this.name,
    required this.borderColor,
    required this.textColor,
  });

  final String name;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 180.w),
      child: IntrinsicWidth(
        child: Container(
          height: AmalTrackerTile.badgeHeight,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.surfaceColor(Colors.white),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              color: textColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
