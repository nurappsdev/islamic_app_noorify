import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_dashboard_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

const _softGreen = Color(0xFFDCE7B8);
const _paleGreen = Color(0xFFEAF1D6);
// Complete-progress bar: fill is a touch darker than the reference's #DCE7B8
// and the percentage segment a touch lighter than its #EAF1D5, so the two
// read as clearly separate on the card gradient.
const _progressFill = Color(0xFFD5E1AC);
const _progressPercent = Color(0xFFEEF4DC);
const _midGreen = Color(0xFF8FA05A);
const _darkGreen = Color(0xFF9DAA5B);
const _deepText = Color(0xFF5E7A4E);

/// One prayer bar in the chart. Kept as plain data so it can later be filled
/// from an API instead of the defaults below.
class PrayerBarData {
  const PrayerBarData({
    required this.name,
    required this.points,
    this.completed = false,
  });

  final String name;
  final int points;
  final bool completed;

  static const defaults = [
    PrayerBarData(name: 'Fajr', points: 2),
    PrayerBarData(name: 'Dhuhr', points: 1),
    PrayerBarData(name: 'Asr', points: 1),
    PrayerBarData(name: 'Maghrib', points: 1),
    PrayerBarData(name: 'Isha', points: 2),
  ];
}

/// Content layer for the Fardh-prayer card. Draws no background of its own -
/// place it inside [HomeGradientShape].
class AmalTrackerCardContent extends StatelessWidget {
  const AmalTrackerCardContent({
    super.key,
    this.percentage = 0,
    this.prayers = PrayerBarData.defaults,
    this.totalPrayers = 7,
    this.completedLabel,
    this.onOpenDashboard,
  });

  /// 0-100.
  final num percentage;
  final List<PrayerBarData> prayers;
  final int totalPrayers;

  /// Overrides the computed "completed/total" text (e.g. the API's `0/7`).
  final String? completedLabel;
  final VoidCallback? onOpenDashboard;

  @override
  Widget build(BuildContext context) {
    final completed = prayers.where((p) => p.completed).length;
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 28.h),
      child: Column(
        children: [
          ProgressHeaderWidget(
            percentage: percentage,
            onTap:
                onOpenDashboard ??
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AmolDashboardScreen(),
                  ),
                ),
          ),
          SizedBox(height: 26.h),
          PrayerSummaryWidget(
            title: 'Fardh Prayer',
            counter: completedLabel ?? '$completed/$totalPrayers',
          ),
          const Spacer(),
          PrayerProgressBarWidget(prayers: prayers),
        ],
      ),
    );
  }
}

class ProgressHeaderWidget extends StatelessWidget {
  const ProgressHeaderWidget({
    super.key,
    required this.percentage,
    required this.onTap,
  });

  final num percentage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = (percentage / 100).clamp(0, 1).toDouble();
    final label = percentage % 1 == 0
        ? percentage.toStringAsFixed(0)
        : percentage.toStringAsFixed(1);
    final radius = BorderRadius.circular(20.r);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54.h,
            decoration: BoxDecoration(
              color: _progressPercent,
              borderRadius: radius,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Row(
                children: [
                  // Track: the dark fill grows with the percentage and the
                  // title stays centred over it.
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: value,
                              heightFactor: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _progressFill,
                                  borderRadius: radius,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Complete progress',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: homeSerifStyle(
                            fontSize: 16.sp,
                            color: _midGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Percentage: its own lighter segment, outside the fill.
                  SizedBox(
                    width: 56.w,
                    child: Center(
                      child: Text(
                        '$label %',
                        style: TextStyle(fontSize: 15.sp, color: _deepText),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 30.w),
        InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Container(
            width: 54.r,
            height: 54.r,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: _softGreen, width: 1.2),
            ),
            child: Icon(Icons.redo_rounded, size: 22.sp, color: _midGreen),
          ),
        ),
      ],
    );
  }
}

class PrayerSummaryWidget extends StatelessWidget {
  const PrayerSummaryWidget({
    super.key,
    required this.title,
    required this.counter,
  });

  final String title;
  final String counter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w500,
            color: _darkGreen,
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          width: 86.w,
          height: 46.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _paleGreen.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Text(
            counter,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w400,
              color: _midGreen,
            ),
          ),
        ),
      ],
    );
  }
}

class PrayerProgressBarWidget extends StatelessWidget {
  const PrayerProgressBarWidget({super.key, required this.prayers});

  final List<PrayerBarData> prayers;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < prayers.length; i++) ...[
          if (i > 0) SizedBox(width: 9.w),
          PrayerBarItemWidget(prayer: prayers[i]),
        ],
      ],
    );
  }
}

class PrayerBarItemWidget extends StatelessWidget {
  const PrayerBarItemWidget({super.key, required this.prayer});

  final PrayerBarData prayer;

  @override
  Widget build(BuildContext context) {
    final active = prayer.completed;
    return Container(
      width: 42.w,
      height: prayer.points >= 2 ? 131.h : 100.h,
      padding: EdgeInsets.only(bottom: 5.h),
      decoration: BoxDecoration(
        color: active ? _darkGreen : _softGreen,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: active ? 0.18 : 0.08),
            blurRadius: active ? 8.r : 4.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RotatedBox(
                quarterTurns: 3,
                child: Padding(
                  padding: EdgeInsets.only(right: 6.h),
                  child: Text(
                    prayer.name,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: active ? Colors.white : _midGreen,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 27.r,
            height: 27.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              '+${prayer.points}',
              style: TextStyle(fontSize: 11.sp, color: _midGreen),
            ),
          ),
        ],
      ),
    );
  }
}
