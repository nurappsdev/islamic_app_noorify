import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

/// The pastel-green dua card shown on the dashboard's Featured Dua row and on
/// the full Featured Dua list (design `devImg/img_16.png`), with the
/// `assets/svgs/duaF.svg` hills illustration anchored to its bottom edge.
class DuaFeaturedCard extends StatelessWidget {
  const DuaFeaturedCard({super.key, required this.featured, this.onExplore});

  final DuaFeaturedModel featured;

  /// Called when the card is tapped — opens this dua on [DuaReaderScreen].
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final totalDuas = featured.category?.totalDuasCount;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: Material(
        color: context.surfaceColor(const Color(0xFFDCE8C4)),
        child: InkWell(
          onTap: onExplore,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SvgPicture.asset(
                  'assets/svgs/duaF.svg',
                  fit: BoxFit.cover,
                  height: 56.h,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      context.localized(featured.title),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: context.inkColor(const Color(0xFF3C4A28)),
                      ),
                    ),
                    if (totalDuas != null) ...[
                      SizedBox(height: 6.h),
                      Text(
                        context.localizedDigits(
                          '${appText.duaTotalDuaLabel} : $totalDuas',
                        ),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.inkColor(const Color(0xFF5D6B44)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
