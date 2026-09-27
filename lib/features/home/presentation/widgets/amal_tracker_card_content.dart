import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_dashboard_screen.dart';
import 'package:islami_app_noorify/features/amol_tracking/presentation/screens/amol_tracking_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

const _softGreen = Color(0xFFDCE7B8);
const _paleGreen = Color(0xFFEAF1D6);
// Complete-progress bar colours, sampled from devImg/img_51.png.
const _progressFill = Color(0xFFDAE5B8);
const _progressPercent = Color(0xFFEAF1D6);
const _midGreen = Color(0xFF8FA05A);
const _darkGreen = Color(0xFFA1AD59);
const _deepText = Color(0xFF5E7A4E);
// Soft warning tone for a prayer whose time passed without being tracked.
const _missedRed = Color(0xFFF3B5B5);

/// One prayer bar in the chart. Kept as plain data so it can later be filled
/// from an API instead of the defaults below.
class PrayerBarData {
  const PrayerBarData({
    required this.name,
    required this.points,
    this.trackingName,
    this.completed = false,
    this.isMissed = false,
  });

  final String name;
  final String? trackingName;
  final int points;

  /// Tracked by the user; drawn dark green. Also feeds the completed counter.
  final bool completed;

  /// Its time has started or passed and it isn't tracked; gets the soft red bar. Only
  /// shown when the prayer isn't [completed].
  final bool isMissed;

  static const defaults = [
    PrayerBarData(name: 'Fajr', trackingName: 'Fajr', points: 2),
    PrayerBarData(name: 'Dhuhr', trackingName: 'Dhuhr', points: 1),
    PrayerBarData(name: 'Asr', trackingName: 'Asr', points: 1),
    PrayerBarData(name: 'Magrib', trackingName: 'Magrib', points: 1),
    PrayerBarData(name: 'Isha', trackingName: 'Isha', points: 2),
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
    this.title = 'Fardh Prayer',
    this.percentageLabel,
    this.onOpenDashboard,
    this.onPrayerTap,
  });

  /// 0-100.
  final num percentage;
  final List<PrayerBarData> prayers;
  final int totalPrayers;

  /// Overrides the computed "completed/total" text (e.g. the API's `0/7`).
  final String? completedLabel;
  final String title;
  final String? percentageLabel;
  final VoidCallback? onOpenDashboard;

  /// Overrides what tapping a prayer bar does (default: open the tracker on
  /// that prayer).
  final ValueChanged<PrayerBarData>? onPrayerTap;

  @override
  Widget build(BuildContext context) {
    final completed = prayers.where((p) => p.completed).length;
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 28.h),
      child: Column(
        children: [
          ProgressHeaderWidget(
            percentage: percentage,
            percentageLabel: percentageLabel,
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
            title: title,
            counter: completedLabel ?? '$completed/$totalPrayers',
          ),
          const Spacer(),
          PrayerProgressBarWidget(
            prayers: prayers,
            onPrayerTap:
                onPrayerTap ??
                (prayer) => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AmolTrackingScreen(
                      selectedPrayer: prayer.trackingName ?? prayer.name,
                      selectedSection: AmalSection.fardhPrayer,
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class ProgressHeaderWidget extends StatelessWidget {
  const ProgressHeaderWidget({
    super.key,
    required this.percentage,
    this.percentageLabel,
    required this.onTap,
  });

  final num percentage;
  final String? percentageLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = (percentage / 100).clamp(0, 1).toDouble();
    final appText = AppText.of(context);
    final calculatedLabel = percentage % 1 == 0
        ? percentage.toStringAsFixed(0)
        : percentage.toStringAsFixed(1);
    final label = percentageLabel?.trim().isNotEmpty == true
        ? percentageLabel!.trim()
        : context.localizedDigits(calculatedLabel);
    final radius = BorderRadius.circular(24.r);
    final percentWidth = 56.w;
    return Row(
      children: [
        Expanded(
          // At 100% the bar gives way to the same pill the Quran card uses.
          child: percentage >= 100
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 46.h,
                    padding: EdgeInsets.symmetric(horizontal: 26.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: _softGreen, width: 1.2),
                    ),
                    child: Text(
                      appText.percentCompleteSuffix,
                      style: homeSerifStyle(
                        fontSize: 18.sp,
                        color: Colors.black,
                      ),
                    ),
                  ),
                )
              : Container(
                  height: 54.h,
                  decoration: BoxDecoration(
                    color: _progressPercent,
                    borderRadius: radius,
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // The fill grows with the percentage but stops where the
                        // percentage segment begins.
                        // It never shrinks below the title, so the two colours stay
                        // separate even at 0%.
                        final maxFill = constraints.maxWidth - percentWidth;
                        final fillWidth = (value * constraints.maxWidth).clamp(
                          (160.w).clamp(0.0, maxFill),
                          maxFill,
                        );
                        return Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: fillWidth,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _progressFill,
                                  borderRadius: radius,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: fillWidth,
                              child: Center(
                                child: Text(
                                  appText.percentCompleteSuffix,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: homeSerifStyle(
                                    fontSize: 16.sp,
                                    color: Color(0xFF859065),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              width: percentWidth,
                              child: Center(
                                child: Text(
                                  '${context.localizedDigits(label)} %',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    color: _deepText,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
        ),
        SizedBox(width: 34.w),
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: onTap,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
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
            fontSize: 26.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
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
            context.localizedDigits(counter),
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
  const PrayerProgressBarWidget({
    super.key,
    required this.prayers,
    this.onPrayerTap,
  });

  final List<PrayerBarData> prayers;
  final ValueChanged<PrayerBarData>? onPrayerTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < prayers.length; i++) ...[
          if (i > 0) SizedBox(width: 9.w),
          PrayerBarItemWidget(
            prayer: prayers[i],
            onTap: onPrayerTap == null ? null : () => onPrayerTap!(prayers[i]),
          ),
        ],
      ],
    );
  }
}

class PrayerBarItemWidget extends StatelessWidget {
  const PrayerBarItemWidget({super.key, required this.prayer, this.onTap});

  final PrayerBarData prayer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Priority: tracked (dark green), then missed (soft red), else the
    // default light green. The running prayer gets no special colour.
    final active = prayer.completed;
    final missed = !active && prayer.isMissed;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: prayer.points >= 2 ? 131.h : 100.h,
        padding: EdgeInsets.only(bottom: 5.h),
        decoration: BoxDecoration(
          color: active
              ? _darkGreen
              : missed
              ? _missedRed
              : _softGreen,
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
                    padding: EdgeInsets.only(left: 12.h),
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
                '+${context.localizedDigits('${prayer.points}')}',
                style: TextStyle(fontSize: 11.sp, color: _midGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
