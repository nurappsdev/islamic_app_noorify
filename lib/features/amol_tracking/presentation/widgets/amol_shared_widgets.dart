import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/shared/widgets/amal_tracker_tile.dart';

const amolOlive = Color(0xFF8D9B70);
const amolCardGreen = Color(0xFFE3ECAE);

String formatAmolDate(DateTime date, AppText appText) {
  final weekday = appText.weekdayNames[date.weekday - 1];
  final month = appText.monthNames[date.month - 1];
  return '$weekday ${date.day} $month, ${date.year}';
}

class AmolHeader extends StatelessWidget {
  const AmolHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 9.h, 14.w, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: AppText.of(context).back,
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: context.surfaceColor(Color(0xFFF7F5CE)),
                foregroundColor: context.inkColor(Color(0xFF526044)),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: context.inkColor(amolOlive),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Today's Amol track" card. Same design as the Home slider's card (both
/// render [AmalTrackerTile]).
class AmolSummaryCard extends StatelessWidget {
  const AmolSummaryCard({
    super.key,
    required this.pointLabel,
    required this.progressLabel,
    required this.progress,
  });

  final String pointLabel;
  final String progressLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return AmalTrackerTile(
      title: AppText.of(context).todaysAmolTrack,
      subtitle: pointLabel,
      progressLabel: progressLabel,
      progress: progress,
    );
  }
}
