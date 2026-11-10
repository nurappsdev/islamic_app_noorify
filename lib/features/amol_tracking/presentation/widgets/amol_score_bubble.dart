import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';

/// The small circular pill shown at each of "my"/the competitor's chart
/// points, carrying a 1-2 letter initials [label].
class AmolScoreBubble extends StatelessWidget {
  const AmolScoreBubble({
    super.key,
    required this.label,
    required this.pillColor,
    this.solid = false,
  });

  final String label;
  final Color pillColor;

  /// True for the bar/column layout: the circle sits directly on the bar
  /// it labels, so it's filled in that bar's exact color instead of a
  /// softened one.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18.r,
      height: 18.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.surfaceColor(
          solid ? pillColor : pillColor.withValues(alpha: .55),
        ),
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.sp,
          fontWeight: FontWeight.w700,
          color: context.inkColor(Color(0xFF3F4A32)),
        ),
      ),
    );
  }
}
