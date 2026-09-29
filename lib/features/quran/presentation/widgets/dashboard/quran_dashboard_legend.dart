import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';

/// Static indicator dot with label for "My Position".
class QuranLegendDot extends StatelessWidget {
  const QuranLegendDot({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14.r,
          height: 14.r,
          decoration: BoxDecoration(
            color: context.surfaceColor(color),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w500,
              color: context.inkColor(color),
            ),
          ),
        ),
      ],
    );
  }
}

/// Legend item with toggle switch for "My Nearest Or Competitor" (matching Hadith dashboard).
class QuranLegendToggle extends StatelessWidget {
  const QuranLegendToggle({
    super.key,
    required this.color,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final Color color;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14.r,
            height: 14.r,
            decoration: BoxDecoration(
              color: context.surfaceColor(
                value ? color : const Color(0xFFCFD3C2),
              ),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w500,
                color: context.inkColor(
                  value ? color : const Color(0xFFA3A996),
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeThumbColor: Colors.white,
              activeTrackColor: color,
            ),
          ),
        ],
      ),
    );
  }
}
