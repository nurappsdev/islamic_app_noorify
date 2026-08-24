import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/widgets/amol_progress_ring.dart';

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
                backgroundColor: const Color(0xFFF7F5CE),
                foregroundColor: const Color(0xFF526044),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: amolOlive,
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: amolCardGreen,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Container(
            width: 52.r,
            height: 52.r,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8E8),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Image.asset(
              'assets/noorifyLogo.png',
              fit: BoxFit.contain,
              color: const Color(0xFF879461),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppText.of(context).todaysAmolTrack,
                  style: TextStyle(fontSize: 14.sp, color: Colors.black),
                ),
                SizedBox(height: 5.h),
                Text(
                  pointLabel,
                  style: TextStyle(fontSize: 11.sp, color: Colors.black87),
                ),
              ],
            ),
          ),
          AmolProgressRing(
            label: progressLabel,
            progress: progress,
            dimension: 74.r,
            holeDimension: 50.r,
            holeColor: amolCardGreen,
            labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
