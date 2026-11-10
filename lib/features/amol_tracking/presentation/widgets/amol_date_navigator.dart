import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';

class AmolDateNavigator extends StatelessWidget {
  const AmolDateNavigator({
    super.key,
    required this.label,
    required this.subtitle,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final String subtitle;

  /// `null` disables the arrow — the server said there's nothing further
  /// that way (`navigation.hasPrevious`/`hasNext`).
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: context.lineColor(Color(0xFFDCE9B8))),
      ),
      child: Row(
        children: [
          _AmolNavArrow(icon: Icons.chevron_left, onTap: onPrevious),
          Expanded(
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: context.inkColor(Colors.black),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: context.inkColor(Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          _AmolNavArrow(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _AmolNavArrow extends StatelessWidget {
  const _AmolNavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox.square(
      dimension: 32.r,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: context.surfaceColor(
            enabled ? Colors.white : const Color(0xFFF2F3EA),
          ),
          side: BorderSide(color: context.lineColor(Color(0xFFDCE9B8))),
        ),
        icon: Icon(
          icon,
          size: 16.sp,
          color: context.inkColor(
            enabled ? const Color(0xFF7E8C61) : const Color(0xFFC5CAB8),
          ),
        ),
      ),
    );
  }
}
