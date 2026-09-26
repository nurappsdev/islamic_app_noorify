import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_dashboard_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

const _softGreen = Color(0xFFDCE7B8);
const _paleGreen = Color(0xFFEAF1D6);
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
      padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 14.h),
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
          SizedBox(height: 14.h),
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
    final radius = BorderRadius.circular(16.r);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48.h,
            decoration: BoxDecoration(color: _paleGreen, borderRadius: radius),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: value,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _softGreen,
                            borderRadius: radius,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Complete progress',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: homeSerifStyle(
                              fontSize: 16.sp,
                              color: _midGreen,
                            ),
                          ),
                        ),
                        Text(
                          '$label %',
                          style: TextStyle(fontSize: 14.sp, color: _deepText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: onTap,
          child: Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: _softGreen, width: 1.2),
            ),
            child: Icon(Icons.redo_rounded, size: 20.sp, color: _midGreen),
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
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 8.h),
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < prayers.length; i++) ...[
          if (i > 0) SizedBox(width: 6.w),
          Expanded(child: PrayerBarItemWidget(prayer: prayers[i])),
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
      height: 100.h + 22.h * prayer.points,
      padding: EdgeInsets.only(bottom: 6.h),
      decoration: BoxDecoration(
        color: active ? _darkGreen : _softGreen,
        borderRadius: BorderRadius.circular(40.r),
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
                  padding: EdgeInsets.only(right: 8.h),
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
            width: 30.r,
            height: 30.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              '+${prayer.points}',
              style: TextStyle(fontSize: 12.sp, color: _midGreen),
            ),
          ),
        ],
      ),
    );
  }
}
