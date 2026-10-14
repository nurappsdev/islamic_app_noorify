import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

/// [status]'s label in the app's language — `in_progress`, `completed` or
/// `abandoned`, as `GET /duas/planner/plans` / `GET /duas/planner/plans/{id}`
/// report it.
String duaPlanStatusLabel(AppText appText, String status) => switch (status) {
  'completed' => appText.planStatusCompleted,
  'abandoned' => appText.planStatusAbandoned,
  _ => appText.planStatusInProgress,
};

/// A small colored pill showing a plan's status — e.g. on
/// [DuaPlanDetailScreen]'s header and each [DuaPlannerScreen] plan card.
class DuaPlanStatusBadge extends StatelessWidget {
  const DuaPlanStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final completed = status == 'completed';
    final abandoned = status == 'abandoned';
    final color = completed
        ? const Color(0xFF6E8B3D)
        : abandoned
        ? const Color(0xFFB0574A)
        : const Color(0xFFA5B657);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(color.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color),
      ),
      child: Text(
        duaPlanStatusLabel(appText, status),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: context.inkColor(color),
        ),
      ),
    );
  }
}
